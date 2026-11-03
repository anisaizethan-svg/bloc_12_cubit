# Flutter BLoC & Cubit User List

An educational Flutter app using event-based `flutter_bloc` 8.1.6, an independent internet Cubit, HTTP, Equatable, and a repository. Users come from https://jsonplaceholder.typicode.com/users; production code contains no fixture user list.

## Run

With Flutter installed:

```sh
flutter pub get
flutter run -d chrome
```

Or choose an Android/iOS emulator or physical device with `flutter devices` and `flutter run -d <device-id>`. macOS is also supported (`flutter run -d macos`) with Xcode installed.

Press **Load** to fetch users, **Clear** to empty the list, and **Load** again to reload. Load is disabled during requests; Clear also invalidates a pending response. Errors appear in the list area and Load retries.

The blue AppBar reports connectivity. InternetCubit checks network interfaces and an uncached HTTPS request to the API host on startup, interface changes, and every 15 seconds. Checks time out after five seconds. The title therefore reflects API reachability; a service outage can appear offline. Interface status alone does not establish internet access. Subscriptions, timer, and HTTP clients are disposed.

## Structure

- `lib/model/`: immutable user model and JSON conversion.
- `lib/services/`: HTTP status/JSON/timeout validation and repository.
- `lib/bloc/`: user events, states, loading, errors, and request invalidation.
- `lib/cubit/`: independent connection monitoring.
- `lib/pages/` and `lib/widgets/`: compact striped list and Load/Clear controls.
- `lib/main.dart`: repository ownership, MultiBlocProvider, Material 2 theme.

Android production internet permissions and macOS client entitlements are included. HTTPS requires no iOS transport exceptions.

## Verify

```sh
flutter analyze
flutter test
flutter build web
```

Tests inject HTTP responses and connection streams to cover errors, retry, duplicate requests, Clear during loading, buttons, and connectivity changes. These fixtures are confined to tests. Live API and device offline/online behavior should also be checked on the target device. No screenshot was included with the supplied specification; styling follows its written requirements.
