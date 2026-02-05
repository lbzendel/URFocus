//
//  SharedGoalManager.swift
//  URFocus
//
//  Created by Lior Zendel on 10/17/25.
//

import Foundation
internal import Combine

// Shared goal model (no FirestoreSwift helpers needed)
// Represents the shared focused time statistics and goal in seconds (e.g., 600,000 seconds = 10,000 minutes)
struct SharedGoal {
    var sessionsCompleted: Int  // Number of completed focus sessions
    var secondsFocused: Int     // Total focused seconds
    var goalTarget: Int         // Goal target in seconds (e.g., 600,000 seconds for 10,000 minutes)
    var updatedAt: Date?
}

final class SharedGoalManager: ObservableObject {
    static let shared = SharedGoalManager()

    @Published var goal: SharedGoal?
    private var refreshTimer: Timer?

    // Start a realtime listener on the shared goal doc
    func startListening() {
        stopListening()
        fetchSharedGoal()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchSharedGoal()
        }
    }

    func stopListening() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Call this when a user completes a focused session.
    /// Increments the total focused time and sessions count.
    /// Goal is tracked in focused seconds (e.g., 600,000 seconds = 10,000 minutes).
    func recordCompletion(seconds: Int) {
        CloudKitService.shared.recordSharedCompletion(seconds: seconds) { [weak self] result in
            switch result {
            case .success(let goal):
                DispatchQueue.main.async {
                    self?.goal = goal
                }
            case .failure(let error):
                print("CloudKit shared goal update failed: \(error)")
            }
        }
    }

    private func fetchSharedGoal() {
        CloudKitService.shared.fetchSharedGoal { [weak self] result in
            switch result {
            case .success(let goal):
                DispatchQueue.main.async {
                    self?.goal = goal
                }
            case .failure(let error):
                print("CloudKit shared goal fetch failed: \(error)")
            }
        }
    }
}
