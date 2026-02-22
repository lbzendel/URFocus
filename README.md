# URFocus

<p align="center">
  <img src="URFocus/Assets.xcassets/AppIcon.appiconset/UR-Focus_Logo.png" alt="URFocus logo" width="120" />
</p>

<p align="center">
  <strong>URFocus</strong> is a SwiftUI focus timer app with shared campus progress, streaks, coins, a shop, and a to-do list.
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-iOS-blue" />
  <img alt="Language" src="https://img.shields.io/badge/Language-Swift-orange" />
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-0A84FF" />
  <img alt="Backend" src="https://img.shields.io/badge/Backend-CloudKit-2E8B57" />
</p>

## Overview

URFocus helps users run focused sessions and track progress both personally and as part of a shared campus-wide goal.

## Features

- Focus timer with start, pause, resume, reset, and local completion notifications.
- Configurable session length (1-120 minutes).
- Personal streak tracking and coin rewards.
- Shared "Campus Goal" progress synced through CloudKit.
- Leaderboard for top focused minutes and daily streaks.
- In-app shop with purchasable/equippable themes.
- Username onboarding and persistent local profile stats.
- Built-in to-do list tab for quick task capture.

## Tech Stack

- Swift + SwiftUI
- CloudKit (`publicCloudDatabase`) for shared goal + leaderboard data
- `@AppStorage` / `UserDefaults` for local persistence
- UserNotifications for session completion alerts

## Project Structure

```text
URFocus/
├── URFocusApp.swift            # App entry point
├── ContentView.swift           # Main tab container + timer UI
├── TodoListView.swift          # To-do list module
├── SharedGoalManager.swift     # Shared goal state + polling
├── CloudKitService.swift       # CloudKit read/write logic
├── UserManager.swift           # Username and local user stats
├── LeaderboardView.swift       # Top users by minutes/streaks
├── ShopView.swift              # Coins and theme unlocks
└── Assets.xcassets/            # Icons, character art, backgrounds
```

## Getting Started

1. Open `URFocus.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Build and run.

## CloudKit Setup

This app relies on CloudKit public database records:

- `SharedGoal` (record ID: `global`)
  - `sessionsCompleted` (Int)
  - `secondsFocused` (Int)
  - `goalTarget` (Int, defaults to `600_000`)
  - `updatedAt` (Date)
- `LeaderboardEntry` (record ID: user ID)
  - `displayName` (String)
  - `minutesFocused` (Int)
  - `streakDays` (Int)
  - `sessionsCompleted` (Int)
  - `updatedAt` (Date)


## Notes

- Focus and profile state is stored locally via `@AppStorage`.
- Shared stats and leaderboard are network-backed via CloudKit.
- Prev. versions used Firebase packages but current app logic before switching to Cloudkit.
