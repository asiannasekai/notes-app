import SwiftUI
import PencilKit

struct NoteEditorView: View {
    let note: Note
    @ObservedObject var viewModel: NotesViewModel
    @State private var title: String
    @State private var content: String
    @State private var canvasView = PKCanvasView()
    @State private var showingDrawing = false
    @State private var autoSaveTimer: Timer?
    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: Color = .black
    @State private var showingToolPicker = false
    
    enum DrawingTool {
        case pen
        case pencil
        case marker
        case eraser
    }
    
    init(note: Note, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Title", text: $title)
                    .font(.title)
                    .padding()
                    .onChange(of: title) { _ in
                        autoSave()
                    }
                
                if showingDrawing {
                    VStack(spacing: 0) {
                        DrawingView(canvasView: $canvasView, selectedTool: selectedTool, selectedColor: selectedColor)
                            .frame(maxHeight: .infinity)
                        
                        // Tool Selection Bar
                        HStack(spacing: 20) {
                            ForEach([DrawingTool.pen, .pencil, .marker, .eraser], id: \.self) { tool in
                                Button(action: {
                                    selectedTool = tool
                                }) {
                                    Image(systemName: toolIcon(for: tool))
                                        .foregroundColor(selectedTool == tool ? .blue : .gray)
                                }
                            }
                            
                            // Color Picker
                            ColorPicker("", selection: $selectedColor)
                                .labelsHidden()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .shadow(radius: 1)
                    }
                } else {
                    TextEditor(text: $content)
                        .font(.body)
                        .onChange(of: content) { _ in
                            autoSave()
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDrawing.toggle()
                    }) {
                        Image(systemName: showingDrawing ? "keyboard" : "pencil.tip")
                    }
                }
            }
            .onAppear {
                setupAutoSave()
            }
            .onDisappear {
                autoSaveTimer?.invalidate()
                autoSaveTimer = nil
                saveNote()
            }
        }
    }
    
    private func toolIcon(for tool: DrawingTool) -> String {
        switch tool {
        case .pen: return "pencil.tip"
        case .pencil: return "pencil"
        case .marker: return "highlighter"
        case .eraser: return "eraser"
        }
    }
    
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            autoSave()
        }
    }
    
    private func autoSave() {
        saveNote()
    }
    
    private func saveNote() {
        var updatedNote = note
        updatedNote.title = title
        updatedNote.content = content
        updatedNote.lastModified = Date()
        viewModel.updateNote(updatedNote)
    }
}

struct DrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let selectedTool: NoteEditorView.DrawingTool
    let selectedColor: Color
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        updateTool()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        updateTool()
    }
    
    private func updateTool() {
        let ink: PKInk
        switch selectedTool {
        case .pen:
            ink = PKInk(.pen, color: UIColor(selectedColor))
        case .pencil:
            ink = PKInk(.pencil, color: UIColor(selectedColor))
        case .marker:
            ink = PKInk(.marker, color: UIColor(selectedColor))
        case .eraser:
            ink = PKInk(.eraser, color: .clear)
        }
        canvasView.tool = PKInkingTool(ink, width: selectedTool == .marker ? 20 : 2)
    }
} 