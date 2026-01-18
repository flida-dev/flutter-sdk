# Flida Auth SDK

Официальный Flutter SDK для интеграции аутентификации Flida в ваши приложения (Android, iOS, Web).

## Установка

Добавьте зависимость в `pubspec.yaml`:

```yaml
dependencies:
  flida_auth_sdk: ^latest_version
```

Выполните команду:
```bash
flutter pub get
```

## Конфигурация

### Android

1. **Gradle Setup:**
   Убедитесь, что `minSdkVersion` в `android/app/build.gradle` не ниже 21.

2. **Redirect URI:**
   В `android/app/build.gradle` добавьте `manifestPlaceholders`:

   ```groovy
   android {
       defaultConfig {
           // ...
           manifestPlaceholders = [
               flidaAuthHost: "YOUR_CLIENT_ID.api.flida.dev"
           ]
       }
   }
   ```
   Замените `YOUR_CLIENT_ID` на ваш реальный Client ID.

### iOS

1. **Info.plist:**
   Добавьте следующие ключи в `ios/Runner/Info.plist`:

   ```xml
   <key>FlidaAuthHost</key>
   <string>YOUR_CLIENT_ID.api.flida.dev</string>
   
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>flida{YOUR_CLIENT_ID}</string>
           </array>
       </dict>
   </array>
   ```
   **Важно:** URL Scheme должен быть в формате `flida` + ваш Client ID.

### Web

1. **index.html:**
   Добавьте мета-тег конфигурации в файл `web/index.html` внутри тега `<head>`:

   ```html
   <meta name="flida-config" content="YOUR_CLIENT_ID.api.flida.dev">
   ```
   
   Опционально можно указать свой redirect URI (по умолчанию используется текущий домен):
   ```html
   <meta name="flida-redirect-uri" content="http://localhost:3000/callback">
   ```

## Использование

### Импорт

```dart
import 'package:flida_auth_sdk/flida_auth_sdk.dart';
```

### Вход (Sign In)

```dart
Future<void> signIn() async {
  try {
    final token = await FlidaAuthSdk.signIn(
      scopes: ['openid', 'name', 'e-mail-address', 'phone-number'],
    );
    
    if (token != null) {
      print('Access Token: ${token.accessToken}');
    }
  } catch (e) {
    print('Ошибка входа: $e');
  }
}
```

### Получение информации о пользователе

```dart
Future<void> getUserInfo(String accessToken) async {
  try {
    final user = await FlidaAuthSdk.getUserInfo(accessToken: accessToken);
    if (user != null) {
        print('Пользователь: ${user.name}, ID: ${user.id}');
    }
  } catch (e) {
    print('Ошибка получения данных: $e');
  }
}
```

### Обновление токенов

```dart
Future<void> refreshToken(String refreshToken) async {
  try {
    final newToken = await FlidaAuthSdk.refreshTokens(
      refreshToken: refreshToken
    );
    print('Новый Access Token: ${newToken?.accessToken}');
  } catch (e) {
    print("Ошибка обновления токена: $e");
  }
}
```

### Выход (Sign Out)

```dart
await FlidaAuthSdk.signOut();
```

### События

Подписка на события аутентификации:

```dart
FlidaAuthSdk.events.listen((event) {
  switch (event.type) {
    case FlidaEventType.signedIn:
      print('Пользователь вошел: ${event.user?.name}');
    case FlidaEventType.loggedOut:
      print('Пользователь вышел. Причина: ${event.logoutReason}');
    case FlidaEventType.signInFailed:
      print('Ошибка входа: ${event.error}');
    default:
      break;
  }
});
```
