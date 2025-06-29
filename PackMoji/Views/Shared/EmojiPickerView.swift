import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    
    let emojis = ["📦", "👕", "👖", "🧥", "👔", "👗", "🩳", "🧦", "👟", "🧢",
                  "🧴", "🪥", "🧼", "🧻", "💊", "🩹", "🔋", "📱", "💻", "🔌",
                  "🎮", "📚", "📝", "🎨", "🎭", "🎪", "🎯", "🎲", "🎸", "🎺",
                  "⚽️", "🏈", "🎾", "🏓", "🎱", "🥊", "🎣", "⛳️", "🎽", "🛹",
                  "🛂", "🎫", "💳", "💵", "🪪", "📄", "📋", "🗂️", "📁", "📅",
                  "🧳", "🎒", "👜", "💼", "🎿", "🏂", "🏊‍♂️", "🚴‍♂️", "⛺️", "🏕️"]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 8)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.title)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("选择表情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
}

struct EmojiPicker: View {
    @Binding var emoji: String
    @State private var showEmojiPicker = false
    
    var body: some View {
        Button {
            showEmojiPicker = true
        } label: {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showEmojiPicker) {
            NavigationStack {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmojiPickerView(selectedEmoji: .constant("📦"))
    }
} 