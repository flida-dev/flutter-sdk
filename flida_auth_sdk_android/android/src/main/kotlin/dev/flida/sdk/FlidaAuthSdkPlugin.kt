package dev.flida.sdk

import android.content.Context
import dev.flida.sdk.models.FlidaEvent
import dev.flida.sdk.models.FlidaEventPublisher
import dev.flida.sdk.models.UserInfoResponse as FlidaUser 
import dev.flida.sdk.models.TokenResponse
import dev.flida.sdk.models.UserInfoResponse
import dev.flida.sdk.models.LogoutReason
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.collect

class FlidaAuthSdkPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var activityBinding: ActivityPluginBinding? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flida_auth_sdk")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flida_auth_sdk/events")
    eventChannel.setStreamHandler(FlidaEventsStreamHandler())
    
    context = flutterPluginBinding.applicationContext
    
    // Initialize SDK with application context
    try {
        FlidaIDSDK.initialize(context)
    } catch (e: Exception) {
        // Might fail if manifest meta-data is missing, which is expected during development/setup
        // We will catch it again when methods are called.
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformName" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "signIn" -> {
        val scopes = call.argument<List<String>>("scopes") ?: emptyList()
        activityBinding?.activity?.let { activity ->
            // Re-initialize to be safe or ensure it's ready.
            try {
                 FlidaIDSDK.shared.signIn(activity, scopes) { authResult ->
                    authResult.fold(
                        onSuccess = { tokenResponse -> 
                            result.success(tokenResponse.toMap())
                        },
                        onFailure = { error ->
                            result.error("SIGN_IN_FAILED", error.message, null)
                        }
                    )
                 }
            } catch (e: Exception) {
                result.error("INIT_FAILED", e.message, null)
            }
        } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
      }
      "signOut" -> {
          FlidaIDSDK.shared.logout()
          result.success(null)
      }
      "refreshTokens" -> {
          FlidaIDSDK.shared.refreshToken { refreshResult ->
               refreshResult.fold(
                   onSuccess = { tokenResponse -> result.success(tokenResponse.toMap()) },
                   onFailure = { error -> result.error("REFRESH_FAILED", error.message, null) }
               )
          }
      }
      "getUserInfo" -> {
          FlidaIDSDK.shared.getUserInfo { userResult ->
              userResult.fold(
                  onSuccess = { user -> result.success(user.toMap()) },
                  onFailure = { error -> result.error("GET_USER_INFO_FAILED", error.message, null) }
              )
          }
      }
      "loadToken" -> {
          val accessToken = FlidaIDSDK.shared.accessToken
          val refreshToken = FlidaIDSDK.shared.refreshToken
          if (accessToken != null && refreshToken != null) {
              result.success(mapOf(
                  "accessToken" to accessToken,
                  "refreshToken" to refreshToken,
                  "expiresIn" to 3600 
              ))
          } else {
              result.success(null)
          }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activityBinding = binding
  }

  override fun onDetachedFromActivity() {
    activityBinding = null
  }
}

// Helpers
fun TokenResponse.toMap(): Map<String, Any> {
    return mapOf(
        "accessToken" to token.accessToken,
        "refreshToken" to token.refreshToken,
        "expiresIn" to token.expiresIn
    )
}

fun UserInfoResponse.toMap(): Map<String, Any> {
    return mapOf(
        "id" to id,
        "name" to name,
        "email" to (emailAddresses?.firstOrNull() ?: null),
        "phoneNumber" to (phoneNumbers?.firstOrNull() ?: null),
        "rawData" to mapOf(
            "emailAddresses" to (emailAddresses ?: emptyList<String>()),
            "phoneNumbers" to (phoneNumbers ?: emptyList<String>())
        )
    ).filterValues { it != null } as Map<String, Any>
}



class FlidaEventsStreamHandler : EventChannel.StreamHandler {
    private var job: Job? = null
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        job = scope.launch {
            FlidaEventPublisher.events.collect { event ->
                events?.success(event.toMap())
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        job?.cancel()
        job = null
    }
}

fun FlidaEvent.toMap(): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    var typeStr = ""
    
    when (this) {
        is FlidaEvent.SignedIn -> {
            typeStr = "signedIn"
            accessToken.let { map["token"] = mapOf("accessToken" to it) }
            user?.let { map["user"] = it.toMap() }
        }
        is FlidaEvent.SignInFailed -> {
            typeStr = "signInFailed"
            map["error"] = mapOf("code" to "SIGN_IN_FAILED", "message" to error.message)
        }
        is FlidaEvent.TokensRefreshed -> {
            typeStr = "tokensRefreshed"
            map["token"] = mapOf("accessToken" to accessToken)
        }
        is FlidaEvent.TokenRefreshFailed -> {
            typeStr = "tokenRefreshFailed"
            map["error"] = mapOf("code" to "REFRESH_FAILED", "message" to error.message)
        }
        is FlidaEvent.LoggedOut -> {
            typeStr = "loggedOut"
            map["logoutReason"] = reason.name.lowercase().let { 
                when(reason) {
                    LogoutReason.USER_INITIATED -> "userInitiated"
                    LogoutReason.SESSION_EXPIRED -> "sessionExpired"
                    LogoutReason.UNAUTHORIZED -> "unauthorized"
                }
            }
        }
        is FlidaEvent.UserInfoFetched -> {
            typeStr = "userInfoFetched"
            map["user"] = user.toMap()
        }
        is FlidaEvent.UserInfoFetchFailed -> {
            typeStr = "userInfoFetchFailed"
            map["error"] = mapOf("code" to "FETCH_FAILED", "message" to error.message)
        }
    }
    map["type"] = typeStr
    return map
}
