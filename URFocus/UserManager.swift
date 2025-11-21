// UserManager.swift
// Handles user onboarding, username, and statistics
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class UserManager: ObservableObject {
    static let shared = UserManager()
    private let db = Firestore.firestore()
    @AppStorage("username") var username: String = ""
    
    // Username onboarding state
    @Published var showUsernamePrompt: Bool = false
    @Published var desiredUsername: String = ""
    @Published var usernameError: String? = nil
    @Published var isCheckingUsername: Bool = false
    
    init() {
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
        db.collection("users")
            .whereField("displayName", isEqualTo: trimmed)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isCheckingUsername = false
                    if let error = error {
                        self.usernameError = "Error checking username: \(error.localizedDescription)"
                        return
                    }
                    if let snapshot = snapshot, !snapshot.documents.isEmpty {
                        self.usernameError = "That username is taken"
                        return
                    }
                    guard let uid = Auth.auth().currentUser?.uid else {
                        self.usernameError = "User not signed in"
                        return
                    }
                    self.db.collection("users").document(uid).setData(["displayName": trimmed], merge: true) { err in
                        DispatchQueue.main.async {
                            if let err = err {
                                self.usernameError = "Failed to save username: \(err.localizedDescription)"
                                return
                            }
                            self.username = trimmed
                            self.usernameError = nil
                            self.showUsernamePrompt = false
                        }
                    }
                }
            }
    }

    // Increment stats after a completed session
    func incrementStats(focusSeconds: Int, streakedToday: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = db.collection("users").document(uid)
        var updates: [String: Any] = [
            "minutesFocused": FieldValue.increment(Int64(focusSeconds/60))
        ]
        if streakedToday {
            updates["streakDays"] = FieldValue.increment(Int64(1))
        }
        doc.setData(updates, merge: true)
    }
}
