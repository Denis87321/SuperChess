# Mobile builds & push notifications

## Apps

Flutter already targets Android/iOS/Web. Release:

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release   # requires Apple Developer team
```

Deep links (configure in `AndroidManifest.xml` / `Info.plist`):

- `superchess://game/<id>`
- `superchess://challenge/<code>`

## Firebase Cloud Messaging

1. Create a Firebase project and add Android/iOS apps.
2. Place `android/app/google-services.json` and iOS `GoogleService-Info.plist`.
3. Apply Google Services Gradle plugin (Android).
4. On first launch, [`lib/notifications/push_service.dart`](../lib/notifications/push_service.dart) registers the device token via `POST /user/devices`.

Without Firebase config, push init is a safe no-op so web/desktop keep working.

## Server send

Set `FCM_SERVER_KEY` on the API. Offline DM attempts call FCM when the peer has a registered device token.

## Server

`user_devices` stores tokens. Wire challenge/DM/seek-matched hooks to your FCM HTTP v1 credentials when ready for production pushes.
