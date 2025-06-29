import SwiftUI

struct CreateTemplateView: View {
    @ObservedObject var viewModel: TemplateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var selectedActivities: Set<String> = []
    
    let activities = [
        "activity_hiking",
        "activity_business",
        "activity_photography",
        "activity_beach",
        "activity_shopping",
        "activity_skiing",
        "activity_city",
        "activity_party"
    ]
    
    private func activityBinding(for activity: String) -> Binding<Bool> {
        Binding(
            get: { selectedActivities.contains(activity) },
            set: { isSelected in
                if isSelected {
                    selectedActivities.insert(activity)
                } else {
                    selectedActivities.remove(activity)
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("template_name_placeholder", text: $name)
                    TextField("template_description_placeholder", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("template_activities_title") {
                    ForEach(activities, id: \.self) { activity in
                        Toggle(LocalizedStringKey(activity), isOn: activityBinding(for: activity))
                    }
                }
            }
            .navigationTitle("templates_create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        createTemplate()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createTemplate() {
        viewModel.createTemplate(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            activities: Array(selectedActivities)
        )
        dismiss()
    }
}

#Preview {
    CreateTemplateView(viewModel: TemplateViewModel())
} 