import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @ObservedObject private var userMgr = UserManager.shared
    @State private var minutesFocused: Int = 0
    @State private var sessionsCompleted: Int = 0
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

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
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading…")
                                .foregroundStyle(.secondary)
                        }
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
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
                    }
                }
            }
            .navigationTitle("Profile")
            .refreshable { await fetchStats() }
            .task { await fetchStats() }
        }
    }

    @MainActor
    private func fetchStats() async {
        isLoading = true
        errorMessage = nil
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Not signed in."
            isLoading = false
            return
        }
        do {
            let db = Firestore.firestore()
            let snap = try await db.collection("users").document(uid).getDocument()
            let data = snap.data() ?? [:]
            self.minutesFocused = data["minutesFocused"] as? Int ?? 0
            self.sessionsCompleted = data["sessionsCompleted"] as? Int ?? 0
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}

#Preview {
    ProfileView()
}
