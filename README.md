# FinU Mobile

FinU is a Flutter finance app for authentication, category budgeting,
transactions, savings, budget warnings, profile photo upload, and transaction
location capture.

## Tech Stack

- Flutter and Dart
- Riverpod for app state
- go_router for navigation
- http for backend API calls
- flutter_secure_storage and shared_preferences for local session/cache data
- flutter_local_notifications for budget warnings
- image_picker for profile photos
- geolocator, flutter_map, and latlong2 for transaction location features

## Backend

The mobile app targets the deployed backend by default:

```text
https://apb-api.denis.my.id
```

This value comes from `AppConfig.defaultApiBaseUrl` in
`lib/src/domain/models.dart`.

## Platform Capabilities

- Internet access for API calls and map tiles
- Notifications for budget warning alerts
- Fine/coarse location on Android and when-in-use location on iOS
- Gallery/photo library access for profile photo updates

## Verification

Run these checks before handing off changes:

```sh
rtk flutter analyze
rtk flutter test
```

Optional dependency review:

```sh
rtk flutter pub outdated
```

## Release Configuration

Platform package identifiers and release signing are still template defaults.
Finalize Android, iOS, and macOS identifiers and configure release signing
before distributing builds. Do not commit signing materials or secret values.
