# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a cross-platform fitness tracking Flutter app with neumorphic design. It supports exercise recording (running, cycling, walking, gym), body metrics tracking (BMI, BMR), and data statistics with local SQLite storage.

## Common Commands

```bash
# Run the app
flutter run

# Run on specific platform
flutter run -d ios
flutter run -d android

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build for iOS
flutter build ios --release

# Build for Android
flutter build apk --release
```

## Architecture

This project uses **Clean Architecture** with four main layers:

### Layer Structure

```
lib/
├── core/                    # Shared utilities, theme, constants, DI
│   ├── constants/           # App constants, DB constants
│   ├── theme/              # Neumorphic theme (light/dark)
│   ├── utils/              # Date, distance, calorie, BMI/BMR calculators
│   ├── widgets/            # Reusable neumorphic widgets
│   └── di/                 # Dependency injection (Provider)
├── data/                   # Data layer
│   ├── database/           # SQLite helper
│   ├── models/             # Data models
│   └── repositories/       # Repository implementations
├── domain/                 # Domain layer
│   ├── entities/           # Business entities
│   └── repositories/       # Repository interfaces
├── presentation/           # UI layer
│   ├── providers/          # State management (Provider/ChangeNotifier)
│   └── screens/            # Pages organized by feature
└── router/                 # GoRouter configuration
```

### State Management

Uses **Provider** with ChangeNotifier pattern. Key providers:
- `ThemeProvider` - Light/dark theme switching
- `ExerciseProvider` - Exercise records CRUD
- `StatisticsProvider` - Statistics aggregation
- `BodyMetricsProvider` - Body metrics (BMI, BMR)

### Data Storage

- **SQLite** via `sqflite` package
- Database name: `super_fitness.db`
- Two main tables: `exercises`, `body_metrics`

### Key Design Patterns

- **Repository Pattern**: Interface in domain, implementation in data layer
- **Provider Pattern**: Dependency injection and state management
- **Neumorphic Design**: Custom shadow-based UI components in `core/widgets/`

## Routes

| Path | Screen |
|------|--------|
| `/` | Home (stats overview) |
| `/exercise` | Exercise list |
| `/exercise/add` | Add exercise |
| `/exercise/active` | GPS workout tracking |
| `/exercise/:id` | Exercise detail |
| `/body` | Body metrics |
| `/body/input` | Input body data |
| `/statistics` | Statistics charts |
| `/settings` | Settings |

## Key Dependencies

- `provider` - State management
- `sqflite` - Local database
- `go_router` - Navigation
- `geolocator` - GPS tracking
- `fl_chart` - Statistics charts
- `intl` - Date formatting
- `uuid` - Unique IDs

## Health Formulas

- **BMI**: weight(kg) / height(m)²
- **BMR (Mifflin-St Jeor)**:
  - Male: 10×weight + 6.25×height - 5×age + 5
  - Female: 10×weight + 6.25×height - 5×age - 161
- **Calories (MET)**: MET × weight(kg) × duration(hours)
