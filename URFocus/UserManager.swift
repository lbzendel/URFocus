// UserManager.swift
// Handles user onboarding, username, and statistics
import Foundation
import SwiftUI
internal import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    @AppStorage("username") var username: String = ""
    @AppStorage("minutesFocused") private var minutesFocused: Int = 0
    @AppStorage("sessionsCompleted") private var sessionsCompleted: Int = 0
    @AppStorage("streakDays") private var streakDays: Int = 0
    @AppStorage("localUserID") private var localUserID: String = ""
    
    // Username onboarding state
    @Published var showUsernamePrompt: Bool = false
    @Published var desiredUsername: String = ""
    @Published var usernameError: String? = nil
    @Published var isCheckingUsername: Bool = false
    
    init() {
        if localUserID.isEmpty {
            localUserID = UUID().uuidString
        }
        if username.isEmpty {
            showUsernamePrompt = true
        }
    }
    
    func checkUsername() {
        let trimmed = desiredUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            usernameError = "Username cannot be empty"
            return
        }
        usernameError = nil
        isCheckingUsername = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.username = trimmed
            self.usernameError = nil
            self.showUsernamePrompt = false
            self.isCheckingUsername = false
            CloudKitService.shared.updateLeaderboardEntry(
                userID: self.localUserID,
                displayName: trimmed,
                minutesFocused: self.minutesFocused,
                streakDays: self.streakDays,
                sessionsCompleted: self.sessionsCompleted
            )
        }
    }

    // Increment stats after a completed session
    func incrementStats(focusSeconds: Int, streakedToday: Bool) {
        let minutesDelta = max(0, focusSeconds / 60)
        minutesFocused += minutesDelta
        sessionsCompleted += 1
        if streakedToday {
            streakDays += 1
        }

        CloudKitService.shared.updateLeaderboardEntry(
            userID: localUserID,
            displayName: username.isEmpty ? "Focus Friend" : username,
            minutesFocused: minutesFocused,
            streakDays: streakDays,
            sessionsCompleted: sessionsCompleted
        )
    }

    func localStats() -> (minutesFocused: Int, sessionsCompleted: Int, streakDays: Int) {
        (minutesFocused, sessionsCompleted, streakDays)
    }
}
