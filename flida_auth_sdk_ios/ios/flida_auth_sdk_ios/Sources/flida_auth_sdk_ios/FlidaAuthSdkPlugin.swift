@preconcurrency import Flutter
import UIKit
import FlidaIDSDK // Ensure this is linked

public class FlidaAuthSdkPlugin: NSObject, FlutterPlugin {
    
    private let eventsHandler = FlidaEventsStreamHandler()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flida_auth_sdk", binaryMessenger: registrar.messenger())
        let instance = FlidaAuthSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let eventChannel = FlutterEventChannel(name: "flida_auth_sdk/events", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance.eventsHandler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformName":
            result("iOS")
            
        case "signIn":
            guard let args = call.arguments as? [String: Any],
                  let scopes = args["scopes"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "scopes is required", details: nil))
                return
            }
            // Need a presentation anchor. For simplicity in plugin we use keyWindow.
            guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Cannot find root view controller", details: nil))
                return
            }
            
            // We need to conform to context providing if needed, or pass the VC which conforms?
            // Flida SDK requires `ASWebAuthenticationPresentationContextProviding`.
            // We can wrap this or assume the VC implements it, but standard UIViewController doesn't.
            // We'll create a helper or extension.
            
            let context = PresentationContextProvider(window: viewController.view.window!)

            FlidaIDSDK.shared.signIn(presenting: context, scopes: scopes) { authResult in
                 switch authResult {
                 case .success(let response):
                     result(response.toMap())
                 case .failure(let error):
                     result(FlutterError(code: "SIGN_IN_FAILED", message: error.localizedDescription, details: nil))
                 }
            }
            
        case "signOut":
            FlidaIDSDK.shared.logout()
            result(nil)

        case "refreshTokens":
             guard let args = call.arguments as? [String: Any],
                  let refreshToken = args["refreshToken"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "refreshToken is required", details: nil))
                return
            }
            
            FlidaIDSDK.shared.refreshTokens(refreshToken: refreshToken) { tokenResult in
                switch tokenResult {
                case .success(let response):
                    result(response.toMap())
                case .failure(let error):
                     result(FlutterError(code: "REFRESH_FAILED", message: error.localizedDescription, details: nil))
                }
            }

        case "getUserInfo":
             guard let args = call.arguments as? [String: Any],
                  let accessToken = args["accessToken"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "accessToken is required", details: nil))
                return
            }
            FlidaIDSDK.shared.getUserInfo(accessToken: accessToken) { userResult in
                switch userResult {
                case .success(let user):
                    result(user.toMap())
                case .failure(let error):
                    result(FlutterError(code: "GET_USER_INFO_FAILED", message: error.localizedDescription, details: nil))
                }
            }

        case "loadToken":
            if let accessToken = FlidaIDSDK.shared.accessToken,
               let refreshToken = FlidaIDSDK.shared.refreshToken {
                // Return a map that mimics TokenResponse/FlidaToken structure
                // Use a default expiresIn since we might not have it stored or it's unknown.
                // Or maybe FlidaIDSDK stores it? The file I saw didn't show expiresIn property in FlidaIDSDK class 
                // but TokenResponse usually has it.
                // Re-reading FlidaIDSDK.swift above: accessToken and refreshToken are stored separately in keychain.
                // No expiresIn stored.
                result([
                    "accessToken": accessToken,
                    "refreshToken": refreshToken,
                    "expiresIn": 3600 // Default/Unknown
                ])
            } else {
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Helpers

import AuthenticationServices

class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return window
    }
}

// MARK: - Mappers

extension TokenResponse {
    func toMap() -> [String: Any] {
        return [
            "accessToken": token.accessToken,
            "refreshToken": token.refreshToken,
            "expiresIn": token.expiresIn
        ]
    }
}

extension UserInfoResponse {
    func toMap() -> [String: Any] {
        var map: [String: Any] = [
            "id": id,
            "name": name,
            "email": emailAddresses?.first as Any,
            "phoneNumber": phoneNumbers?.first as Any,
            "rawData": [
                "emailAddresses": emailAddresses ?? [],
                "phoneNumbers": phoneNumbers ?? []
            ]
        ]
        return map
    }
}

import Combine

class FlidaEventsStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var cancellable: AnyCancellable?

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        cancellable = FlidaEventPublisher.shared.events.sink { event in
            events(event.toMap())
        }
        
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancellable?.cancel()
        cancellable = nil
        eventSink = nil
        return nil
    }
}

extension FlidaEvent {
    func toMap() -> [String: Any] {
        // Map enum based on case
        var typeStr = ""
        var data: [String: Any] = [:]

        switch self {
        case .signedIn(let user, let accessToken):
            typeStr = "signedIn"
            if let u = user { data["user"] = u.toMap() }
            data["token"] = ["accessToken": accessToken] // Partial token data available in event
            
        case .signInFailed(let error):
            typeStr = "signInFailed"
             data["error"] = ["code": "SIGN_IN_FAILED", "message": error.localizedDescription]

        case .tokensRefreshed(let accessToken):
             typeStr = "tokensRefreshed"
             data["token"] = ["accessToken": accessToken]

        case .tokenRefreshFailed(let error):
             typeStr = "tokenRefreshFailed"
             data["error"] = ["code": "REFRESH_FAILED", "message": error.localizedDescription]

        case .loggedOut(let reason):
             typeStr = "loggedOut"
             let reasonStr: String
             switch reason {
             case .userInitiated: reasonStr = "userInitiated"
             case .sessionExpired: reasonStr = "sessionExpired"
             case .unauthorized: reasonStr = "unauthorized"
             }
             data["logoutReason"] = reasonStr

        case .userInfoFetched(let user):
             typeStr = "userInfoFetched"
             data["user"] = user.toMap()

        case .userInfoFetchFailed(let error):
             typeStr = "userInfoFetchFailed"
             data["error"] = ["code": "FETCH_FAILED", "message": error.localizedDescription]
        }
        
        data["type"] = typeStr
        return data
    }
}
