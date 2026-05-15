# RoomLedger

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

RoomLedger is a professional expense management application designed for roommates and personal financial tracking. Built with a focus on speed, privacy, and a sleek dark-mode aesthetic, it facilitates shared cost management and personal spending analysis.

## Features

- **Premium Dark Mode**: A high-contrast dark interface optimized for modern OLED displays.
- **Shared Expenses**: Track communal costs and manage roommate settlements with automated debt calculation.
- **Personal Tracking**: Log private spending across customizable categories.
- **Cash Management**: Monitor physical cash flow, track monthly usage, and manage emergency reserves.
- **Detailed Analytics**: Visualize spending trends and category breakdowns through integrated charting.
- **Smart Reminders**: Integrated reminder tracking for bills and settlements.
- **Backup and Restore**: Local database backup and restoration capabilities.
- **Privacy Centric**: All data is stored locally on the device using SQLite. No external synchronization or data tracking is performed.

## Technology Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Database**: Sqflite (SQLite)
- **Theming**: Material 3 with a Custom Dark Mode Design System

## Getting Started

### Prerequisites

- Flutter SDK (Latest Stable Version)
- Android Studio / VS Code with Flutter extension
- An Android or iOS device/emulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/manish-12ys/roomledger.git
   ```
2. Navigate to the project directory:
   ```bash
   cd roomledger
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```

## Build Instructions

### Android

To build a release APK:
```bash
flutter build apk --release
```
To build an App Bundle for the Google Play Store:
```bash
flutter build appbundle --release
```



## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---
Developed by Manish
