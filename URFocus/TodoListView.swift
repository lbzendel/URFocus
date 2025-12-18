// New SwiftUI view for a simple to-do list page
import SwiftUI

struct TodoItem: Identifiable, Hashable {
    let id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
}

class TodoListManager: ObservableObject {
    @Published var items: [TodoItem] = []
    @Published var newTask: String = ""
    
    func addItem() {
        let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(title: trimmed))
        newTask = ""
    }
    
    func toggleCompleted(for item: TodoItem) {
        if let idx = items.firstIndex(of: item) {
            items[idx].isCompleted.toggle()
        }
    }
    
    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

struct TodoListView: View {
    @StateObject private var manager = TodoListManager()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Add a task...", text: $manager.newTask)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit { manager.addItem() }
                    Button(action: manager.addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                
                if manager.items.isEmpty {
                    Spacer()
                    Text("No tasks yet!")
                        .foregroundStyle(.secondary)
                        .font(.headline)
                    Spacer()
                } else {
                    List {
                        ForEach(manager.items) { item in
                            HStack {
                                Button(action: { manager.toggleCompleted(for: item) }) {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isCompleted ? .green : .gray)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Text(item.title)
                                    .strikethrough(item.isCompleted)
                                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                            }
                        }
                        .onDelete(perform: manager.delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("To-do List")
        }
    }
}

// Optionally, add a basic preview
#Preview {
    TodoListView()
}
