# ELBI Smart BMS

ELBI Smart BMS is a Flutter Android application for adding, configuring, and
monitoring Battery Management Systems over Bluetooth Low Energy (BLE).

Current version: **1.0.4 (build 4)**

## Features

- Add a BMS by scanning a QR code containing its Bluetooth MAC address.
- Discover nearby BLE devices and save devices for later use.
- Connect to a selected saved BMS and display live pack telemetry.
- Display state of charge, voltage, current, temperature, status, and errors.
- Display a flexible number of reported cell voltages with minimum, maximum,
  and difference statistics; unused trailing zero placeholders are hidden.
- Show charging state when current is greater than `0.5 A`.
- Show a low-battery state when SOC is below `15%`.
- Read current device parameters from the telemetry payload.
- Optionally record every valid Bluetooth telemetry packet to a CSV file from
  connection until disconnection. Logs are saved in
  `Download/ELBI Smart BMS`.
- Apply LFP, NMC, or LTO chemistry presets before saving device parameters.
- Edit and send BMS protection, current, temperature, balancing, and system
  parameters.
- Fall back to locally saved or default parameters when telemetry has no
  `settings` object.
- Provide an interactive monitoring and device-settings demo.
- Support English and Bahasa Indonesia, light/dark themes, Celsius/Fahrenheit,
  saved-device management, and an optional raw BLE debug screen.

## Supported platform

The current tested target is Android 7.0 (API 24) or newer. The repository also
contains the Flutter iOS scaffold, but the BLE workflow has not yet been
validated on iOS.

The Android app requests camera access for QR scanning and the appropriate
Bluetooth/location permissions for the installed Android version.

## BLE UART protocol

Communication is restricted to the following UART service and characteristics:

| Purpose | UUID |
| --- | --- |
| UART service | `FFE0` |
| App writes to BMS | `FFE1` |
| BMS notifications to app | `FFE2` |

The app discovers service `FFE0`, writes parameter JSON through `FFE1`, and
subscribes only to notifications from `FFE2`. Long JSON writes are split using
the negotiated BLE MTU.

## Incoming telemetry JSON

The BMS sends valid JSON through `FFE2`. The `settings` object is optional.

```json
{
  "serial_number": "00BB1000",
  "soc": 16,
  "voltage": 50.89,
  "current": -18.34,
  "temperature": 25.0,
  "error_code": 0,
  "cell_voltage": [
    3153, 3185, 3189, 3188, 3184, 3188, 3187, 3174,
    3178, 3178, 3185, 3186, 3186, 3185, 3183, 3163,
    0, 0, 0, 0, 0, 0, 0, 0
  ],
  "settings": {
    "ovp": 3600,
    "ovr": 3550,
    "uvp": 2800,
    "uvr": 2850,
    "occ": 50,
    "docc": 1000,
    "ocd": 100,
    "docd": 1000,
    "otb": 40,
    "otbr": 38,
    "otm": 50,
    "otmr": 45,
    "cap": 100,
    "shunt": 1.5,
    "bal_min": 3500,
    "bal_dif": 50,
    "sleep": 7
  }
}
```

Required telemetry fields are `serial_number`, `soc`, `voltage`, `current`,
`temperature`, `error_code`, and `cell_voltage`. Zero-valued cell entries are
treated as inactive cells.

If `settings` is missing, null, or not an object, telemetry still parses
normally. The Device Settings page then loads values saved for that device and
uses built-in defaults when no saved values exist.

The BLE payload must be strict JSON: comments such as `// ...` are not valid,
and commas between properties are required.

## Outgoing settings JSON

Pressing **Save Parameters** on the Device Settings page sends this compact JSON
object through `FFE1` and saves the values locally after a successful write:

The two over-current delay fields are displayed and edited in seconds. Their
`docc` and `docd` BLE values remain milliseconds for firmware compatibility
(`1 s` is sent as `1000`, for example).

The Battery Type selector applies LFP, NMC, or LTO preset values to the fields
provided by that chemistry preset. Current limits, battery capacity, and shunt
resistance are preserved. Presets remain editable and are not sent until
**Save Parameters** is pressed.

```json
{
  "ovp": 4200,
  "ovr": 4100,
  "uvp": 2800,
  "uvr": 3000,
  "occ": 50,
  "docc": 1000,
  "ocd": 120,
  "docd": 2000,
  "otb": 60,
  "otbr": 50,
  "otm": 85,
  "otmr": 70,
  "cap": 100,
  "shunt": 1.5,
  "bal_min": 3500,
  "bal_dif": 50,
  "sleep": 7
}
```

## QR code format

The QR scanner accepts a separated or compact Bluetooth MAC address, including
an address embedded in surrounding text. Accepted examples:

```text
39:14:10:46:47:C4
39-14-10-46-47-C4
3914104647C4
```

The saved address is normalized to uppercase colon-separated form.

## Development setup

Requirements:

- Flutter SDK with Dart `3.12.2` or newer compatible with `pubspec.yaml`
- Android SDK and platform tools
- Java 17
- A physical Android device for BLE testing

Install dependencies and run the app:

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

## Verification

Run static analysis and the automated test suite:

```bash
flutter analyze
flutter test
```

The tests cover telemetry parsing, optional device settings, outgoing parameter
mapping, MAC address parsing, saved devices, localization/settings, demo mode,
and monitoring UI behavior.

## Build an installable APK

Build the release APK:

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Install it on a connected Android device:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

The current release build uses the debug signing key so it can be installed for
testing. Configure a private production keystore before publishing the app to an
app store or distributing a production release.

## Project structure

```text
lib/
  core/                  Theme and localization helpers
  features/
    devices/             Saved-device model, storage, and selection
    home/                Home screen and menu widgets
    manual/              In-app user manual
    monitoring/          BLE UART, telemetry, demo, monitoring, and debug UI
    scanner/             QR/MAC parsing and nearby BLE discovery
    settings/            App settings and BMS device parameters
    splash/              Branded splash screen
test/                    Unit and widget tests
android/                 Android platform configuration
```

## Privacy and storage

Saved BMS devices, app preferences, and per-device parameter values are stored
locally with `shared_preferences`. The app does not require an account or cloud
service.
