//
//  SharedGoalManager.swift
//  URFocus
//
//  Created by Lior Zendel on 10/17/25.
//

import Foundation
import FirebaseFirestore
internal import Combine

// Shared goal model (no FirestoreSwift helpers needed)
struct SharedGoal {
    var sessionsCompleted: Int
    var secondsFocused: Int
    var goalTarget: Int
    var updatedAt: Timestamp?
}

final class SharedGoalManager: ObservableObject {
    static let shared = SharedGoalManager()

    private let db = Firestore.firestore()
    @Published var goal: SharedGoal?
    private var listener: ListenerRegistration?

    private var docRef: DocumentReference {
        db.collection("shared").document("goal")
    }

    // Start a realtime listener on the shared goal doc
    func startListening() {
        stopListening()
        listener = docRef.addSnapshotListener { [weak self] snap, _ in
            guard let data = snap?.data() else { return }
            let g = SharedGoal(
                sessionsCompleted: data["sessionsCompleted"] as? Int ?? 0,
                secondsFocused:    data["secondsFocused"] as? Int ?? 0,
                goalTarget:        data["goalTarget"] as? Int ?? 0,
                updatedAt:         data["updatedAt"] as? Timestamp
            )
            DispatchQueue.main.async { self?.goal = g }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Call this when a user completes a session.
    func recordCompletion(seconds: Int) {
        // Safety bounds (1 min .. 6 hours)
        let safe = max(60, min(seconds, 6 * 3600))
        docRef.updateData([
            "sessionsCompleted": FieldValue.increment(Int64(1)),
            "secondsFocused": FieldValue.increment(Int64(safe)),
            "updatedAt": FieldValue.serverTimestamp()
        ]) { err in
            if let err = err {
                print("Increment failed: \(err)")
            }
        }
    }
}
