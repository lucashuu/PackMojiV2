import SwiftUI

struct ImportTemplateView: View {
    @ObservedObject var viewModel: TemplateViewModel
    @Binding var importText: String
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $importText)
                        .frame(minHeight: 200)
                } header: {
                    Text("Paste the template data here")
                } footer: {
                    Text("The template data should be in JSON format")
                }
            }
            .navigationTitle("templates_import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        importTemplate()
                    }
                    .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func importTemplate() {
        do {
            try viewModel.importTemplate(from: importText)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    ImportTemplateView(
        viewModel: TemplateViewModel(),
        importText: .constant("")
    )
} 