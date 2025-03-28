import SwiftUI

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var lastModified: Date
    var folder: String
}

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?
    @Published var searchText = ""
    
    private let saveKey = "savedNotes"
    
    init() {
        loadNotes()
    }
    
    func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Note].self, from: data) {
                notes = decoded
            }
        }
    }
    
    func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addNote() {
        let newNote = Note(title: "New Note", content: "", lastModified: Date(), folder: "All Notes")
        notes.append(newNote)
        selectedNote = newNote
        saveNotes()
    }
    
    func deleteNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes.remove(at: index)
            if selectedNote?.id == note.id {
                selectedNote = nil
            }
            saveNotes()
        }
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingNewNote = false
    
    var filteredNotes: [Note] {
        if viewModel.searchText.isEmpty {
            return viewModel.notes
        } else {
            return viewModel.notes.filter { note in
                note.title.localizedCaseInsensitiveContains(viewModel.searchText) ||
                note.content.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredNotes) { note in
                    NoteRow(note: note)
                        .onTapGesture {
                            viewModel.selectedNote = note
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteNote(filteredNotes[index])
                    }
                }
            }
            .navigationTitle("Notes")
            .searchable(text: $viewModel.searchText, prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.addNote()
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(item: $viewModel.selectedNote) { note in
                NoteEditorView(note: note, viewModel: viewModel)
            }
        }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title)
                .font(.headline)
            Text(note.content)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            Text(note.lastModified, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
} 