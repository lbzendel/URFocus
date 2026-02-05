import SwiftUI

struct ProfileView: View {
    @ObservedObject private var userMgr = UserManager.shared
    @State private var minutesFocused: Int = 0
    @State private var sessionsCompleted: Int = 0
    @State private var streakDays: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Label("Username", systemImage: "person")
                        Spacer()
                        Text(userMgr.username.isEmpty ? "(not set)" : userMgr.username)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Your Stats")) {
                    HStack {
                        Label("Total Sessions", systemImage: "checkmark.seal")
                        Spacer()
                        Text("\(sessionsCompleted)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Total Minutes Focused", systemImage: "clock")
                        Spacer()
                        Text("\(minutesFocused)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                        Spacer()
                        Text("\(streakDays) day\(streakDays == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: fetchStats)
            .refreshable { fetchStats() }
        }
    }

    private func fetchStats() {
        let stats = userMgr.localStats()
        minutesFocused = stats.minutesFocused
        sessionsCompleted = stats.sessionsCompleted
        streakDays = stats.streakDays
    }
}

#Preview {
    ProfileView()
}
