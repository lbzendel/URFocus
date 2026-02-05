// LeaderboardView.swift
// Displays top X all-time leaders in minutes focused and daily streaks
import SwiftUI

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

    private func fetchLeaderboard() {
        loading = true
        
        var didLoadMinutes = false
        var didLoadStreaks = false
        
        func checkLoadingComplete() {
            if didLoadMinutes && didLoadStreaks {
                loading = false
            }
        }
        
        CloudKitService.shared.fetchLeaderboard(sortedBy: "minutesFocused", limit: topCount) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entries):
                    self.topMinutes = entries
                case .failure(let error):
                    print("Leaderboard minutes fetch failed: \(error)")
                    self.topMinutes = []
                }
                didLoadMinutes = true
                checkLoadingComplete()
            }
        }

        CloudKitService.shared.fetchLeaderboard(sortedBy: "streakDays", limit: topCount) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entries):
                    self.topStreaks = entries
                case .failure(let error):
                    print("Leaderboard streaks fetch failed: \(error)")
                    self.topStreaks = []
                }
                didLoadStreaks = true
                checkLoadingComplete()
            }
        }
    }
}
