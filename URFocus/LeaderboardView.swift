// LeaderboardView.swift
// Displays top X all-time leaders in minutes focused and daily streaks
import SwiftUI
import FirebaseFirestore

struct LeaderboardEntry: Identifiable, Hashable {
    let id: String
    let displayName: String
    let minutesFocused: Int
    let streakDays: Int
}

struct LeaderboardView: View {
    // Top X leaders to show
    let topCount: Int = 10

    @State private var topMinutes: [LeaderboardEntry] = []
    @State private var topStreaks: [LeaderboardEntry] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Top \(topCount) All-Time Focus (Minutes)")) {
                    if loading {
                        ProgressView()
                    } else {
                        ForEach(topMinutes.prefix(topCount)) { entry in
                            HStack {
                                Text(entry.displayName)
                                Spacer()
                                Text("\(entry.minutesFocused) min")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Top \(topCount) Daily Streaks")) {
                    if loading {
                        ProgressView()
                    } else {
                        ForEach(topStreaks.prefix(topCount)) { entry in
                            HStack {
                                Text(entry.displayName)
                                Spacer()
                                Text("\(entry.streakDays) days")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .onAppear(perform: fetchLeaderboard)
        }
    }

    // Fetch top X leaders from Firestore (adapt collection/field names as needed)
    private func fetchLeaderboard() {
        let db = Firestore.firestore()
        loading = true
        
        var didLoadMinutes = false
        var didLoadStreaks = false
        
        func checkLoadingComplete() {
            if didLoadMinutes && didLoadStreaks {
                loading = false
            }
        }
        
        // Fetch top by minutesFocused
        db.collection("users")
            .order(by: "minutesFocused", descending: true)
            .limit(to: topCount)
            .getDocuments { (snap, err) in
                let entries = snap?.documents.compactMap { doc in
                    let data = doc.data()
                    return LeaderboardEntry(
                        id: doc.documentID,
                        displayName: data["displayName"] as? String ?? "(anon)",
                        minutesFocused: data["minutesFocused"] as? Int ?? 0,
                        streakDays: data["streakDays"] as? Int ?? 0
                    )
                } ?? []
                DispatchQueue.main.async {
                    self.topMinutes = entries as! [LeaderboardEntry]
                    didLoadMinutes = true
                    checkLoadingComplete()
                }
            }
        // Fetch top by streakDays
        db.collection("users")
            .order(by: "streakDays", descending: true)
            .limit(to: topCount)
            .getDocuments { (snap, err) in
                let entries = snap?.documents.compactMap { doc in
                    let data = doc.data()
                    return LeaderboardEntry(
                        id: doc.documentID,
                        displayName: data["displayName"] as? String ?? "(anon)",
                        minutesFocused: data["minutesFocused"] as? Int ?? 0,
                        streakDays: data["streakDays"] as? Int ?? 0
                    )
                } ?? []
                DispatchQueue.main.async {
                    self.topStreaks = entries as! [LeaderboardEntry]
                    didLoadStreaks = true
                    checkLoadingComplete()
                }
            }
    }
}
