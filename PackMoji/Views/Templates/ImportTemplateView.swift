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
                    Text("import_template_paste_instruction")
                } footer: {
                    Text("import_template_format_instruction")
                }
            }
            .navigationTitle("templates_import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("import") {
                        importTemplate()
                    }
                    .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("error_alert_title", isPresented: $showError) {
                Button("error_alert_button", role: .cancel) {}
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