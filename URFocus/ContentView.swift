//
//  ContentView.swift
//  URFocus
//
//  Created by Lior Zendel on 10/17/25.
//

import SwiftUI
import UserNotifications
import FirebaseAuth   // Optional (only if you enabled Anonymous Auth)
import FirebaseFirestore
internal import Combine

struct ContentView: View {
    // MARK: - Shared goal
    @StateObject private var goalMgr = SharedGoalManager.shared

    // MARK: - Persistent user settings
    @AppStorage("goalMinutes") private var goalMinutes: Int = 25
    @AppStorage("streakDays") private var streakDays: Int = 400
    @AppStorage("coins") private var coins: Int = 0
    @AppStorage("useMidnightBlueTheme") private var useMidnightBlueTheme: Bool = false

    // MARK: - Timer state
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var startDate: Date?
    @State private var targetDate: Date?
    @State private var now: Date = .now
    @State private var completedThisRun = false

    // Ticker every second
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var totalSeconds: Double { Double(goalMinutes * 60) }
    var remainingSeconds: Double {
        guard let target = targetDate else { return totalSeconds }
        return max(0, target.timeIntervalSince(now))
    }
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let done = totalSeconds - remainingSeconds
        return min(max(done / totalSeconds, 0), 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (useMidnightBlueTheme ? Color.blue.opacity(0.2) : Color(.systemBackground))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ======= Shared Goal Header =======
                        Text("Campus Goal")
                            .font(.title2.bold())
                            .padding(.top, 8)

                        if let g = goalMgr.goal {
                            SharedProgressView(goal: g)
                        } else {
                            ProgressView().padding(.vertical, 8)
                        }

                        Divider().padding(.vertical, 4)

                        // ======= Personal Timer UI =======
                        Text("Your Session")
                            .font(.title2.bold())

                        ZStack {
                            Circle()
                                .stroke(urBlue.opacity(0.15), lineWidth: 20)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(urYellow.gradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.25), value: progress)

                            VStack(spacing: 6) {
                                Text(remainingSeconds.formattedClock)
                                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                                    .monospacedDigit()

                                Text(goalMinutesLabel)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 260, height: 260)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Length")
                                .font(.headline)
                            Slider(value: Binding(
                                get: { Double(goalMinutes) },
                                set: { goalMinutes = Int($0) }
                            ), in: 1...120, step: 1)
                            .accessibilityLabel("Minutes")
                            .disabled(isRunning && !isPaused)

                            HStack {
                                Text("1 min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(goalMinutes) min")
                                    .font(.caption.bold())
                                Spacer()
                                Text("120 min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button(action: startTapped) {
                                Label(isPaused ? "Resume" : "Start", systemImage: isPaused ? "play.fill" : "timer")
                            }
                            .buttonStyle(FilledButtonStyle(color: urBlue))
                            .disabled(isRunning && !isPaused)

                            Button(action: pauseTapped) {
                                Label("Pause", systemImage: "pause.fill")
                            }
                            .buttonStyle(FilledButtonStyle(color: .gray.opacity(0.5)))
                            .disabled(!isRunning || isPaused)

                            Button(role: .destructive, action: resetTapped) {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(OutlinedButtonStyle())
                            .disabled(!(isRunning || progress > 0))
                        }
                        .padding(.horizontal)

                        HStack {
                            Label("Streak: \(streakDays) day\(streakDays == 1 ? "" : "s")", systemImage: "flame.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            if completedThisRun {
                                Label("Nice!", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .font(.subheadline)
                        .padding(.horizontal)

                        Text("Tip: For hard-core detox, try iOS **Guided Access** (triple-click Side Button).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("UR Focus")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ShopView()
                    } label: {
                        Label("Shop", systemImage: "cart")
                    }
                }
            }
            .onReceive(ticker) { t in
                now = t
                guard isRunning, !isPaused else { return }
                if remainingSeconds <= 0 {
                    onCompleteSession()
                }
            }
            .onAppear {
                now = .now
                ensureSignedInAnonymously() // optional
                goalMgr.startListening()
            }
            .onDisappear { goalMgr.stopListening() }
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: completedThisRun)
        }
    }

    // MARK: - Actions
    private func startTapped() {
        requestNotificationPermissionIfNeeded()
        completedThisRun = false

        if isPaused {
            // resume
            targetDate = Date().addingTimeInterval(remainingSeconds)
            isPaused = false
            isRunning = true
            scheduleEndNotification()
            return
        }

        // fresh start
        startDate = Date()
        targetDate = startDate!.addingTimeInterval(totalSeconds)
        now = .now
        isRunning = true
        isPaused = false
        scheduleEndNotification()
    }

    private func pauseTapped() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        cancelScheduledNotifications()
    }

    private func resetTapped() {
        isRunning = false
        isPaused = false
        startDate = nil
        targetDate = nil
        now = .now
        completedThisRun = false
        cancelScheduledNotifications()
    }

    private func onCompleteSession() {
        isRunning = false
        isPaused = false
        completedThisRun = true
        bumpStreakIfNeeded()
        // Award coins based on session length
        let m = Double(goalMinutes)
        let base = 2.0 * m
        let reward: Int
        if m < 30 {
            reward = Int(base)
        } else {
            reward = Int(floor(base * pow(1.1, m / 30.0)))
        }
        coins += max(reward, 0)
        notifyCompletion()
        hapticSuccess()

        // Push to shared goal
        SharedGoalManager.shared.recordCompletion(seconds: Int(totalSeconds))
    }

    // MARK: - Notifications
    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    private func scheduleEndNotification() {
        guard let targetDate else { return }
        let content = UNMutableNotificationContent()
        content.title = "UR Focus"
        content.body = "🎉 Focus session complete! Great job."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, targetDate.timeIntervalSinceNow),
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "URFocusEnd", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func notifyCompletion() {
        // Foreground completion UX handled in UI/haptics; the scheduled local notification will fire if backgrounded.
    }

    private func cancelScheduledNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["URFocusEnd"])
    }

    // MARK: - Streak (bumps once per calendar day on first completion)
    private func bumpStreakIfNeeded() {
        let key = "lastCompletedDay"
        let today = Calendar.current.startOfDay(for: Date())
        let last = UserDefaults.standard.object(forKey: key) as? Date

        if last == nil || Calendar.current.compare(last!, to: today, toGranularity: .day) == .orderedAscending {
            streakDays += 1
            UserDefaults.standard.set(today, forKey: key)
        }
    }

    // MARK: - Haptics
    private func hapticSuccess() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    // MARK: - UR Colors & labels
    private var urBlue: Color { Color(red: 0/255, green: 51/255, blue: 102/255) }
    private var urYellow: Color { Color(red: 255/255, green: 204/255, blue: 0/255) }

    private var goalMinutesLabel: String {
        if remainingSeconds <= 0 { return "Goal: \(goalMinutes) min — Done!" }
        return "Goal: \(goalMinutes) min"
    }
}

// MARK: - Helpers
private extension Double {
    var formattedClock: String {
        let total = max(0, Int(self))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Auth (optional anonymous sign-in)
func ensureSignedInAnonymously() {
    if Auth.auth().currentUser == nil {
        Auth.auth().signInAnonymously { _, err in
            if let err = err { print("Anon sign-in failed: \(err)") }
        }
    }
}

// MARK: - Button Styles
struct FilledButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(radius: configuration.isPressed ? 0 : 6, y: 2)
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.4), lineWidth: 1)
            )
            .foregroundStyle(.primary)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Shared Progress View
struct SharedProgressView: View {
    let goal: SharedGoal

    // Switch between a campus "sessions" goal or "seconds" goal
    var useSessionsTarget = true

    var progress: Double {
        if useSessionsTarget {
            return goalTarget > 0 ? min(1, Double(goal.sessionsCompleted) / Double(goalTarget)) : 0
        } else {
            return goalTarget > 0 ? min(1, Double(goal.secondsFocused) / Double(goalTarget)) : 0
        }
    }
    var goalTarget: Int { goal.goalTarget }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().stroke(.secondary.opacity(0.15), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.blue, .yellow]), center: .center),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: progress)

                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title2.bold())
                        .monospacedDigit()
                    if useSessionsTarget {
                        Text("\(goal.sessionsCompleted) / \(goalTarget) sessions")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("\(formatSeconds(goal.secondsFocused)) / \(formatSeconds(goalTarget))")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 220, height: 220)

            HStack {
                Label("Sessions: \(goal.sessionsCompleted)", systemImage: "person.3.fill")
                Spacer()
                Label("Focus: \(formatSecondsShort(goal.secondsFocused))", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
        }
    }

    private func formatSeconds(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    private func formatSecondsShort(_ s: Int) -> String {
        let h = s / 3600
        let m = (s % 3600) / 60
        return h > 0 ? "\(h)h" : "\(m)m"
    }
}

struct ShopView: View {
    @AppStorage("coins") private var coins: Int = 0
    @AppStorage("useMidnightBlueTheme") private var useMidnightBlueTheme: Bool = false
    struct ShopItem: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let cost: String
    }

    private let items: [ShopItem] = [
        .init(name: "Focus Theme: Midnight Blue",
              description: "A deep, calming color theme for late-night grinds.",
              cost: "300 points"),
        .init(name: "Sticker Pack: Study Gremlins",
              description: "Silly little critters to cheer you on in the UI.",
              cost: "500 points"),
        .init(name: "Title: Library Goblin",
              description: "Show off your streak with a goofy profile title.",
              cost: "800 points")
    ]

    var body: some View {
        List {
            Section(header: Text("Your Balance")) {
                HStack {
                    Label("Coins: \(coins)", systemImage: "creditcard.circle.fill")
                        .font(.headline)
                }
            }
            Section(header: Text("UR Focus Shop")) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.cost)
                                .font(.caption.bold())
                                .padding(6)
                                .background(Color.yellow.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        HStack {
                            Spacer()
                            Button {
                                // Simple purchase hook for the Midnight Blue theme
                                if item.name == "Focus Theme: Midnight Blue" {
                                    // Optionally check coins & deduct later; for now just apply the theme
                                    useMidnightBlueTheme = true
                                }
                                // TODO: Hook up purchase logic for other items
                            } label: {
                                Label("Buy", systemImage: "cart.badge.plus")
                            }
                            .buttonStyle(FilledButtonStyle(color: Color.accentColor))
                            Spacer()
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Shop")
    }
}
