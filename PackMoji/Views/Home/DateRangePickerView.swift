import SwiftUI

struct DateRangePickerView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    var onDismiss: () -> Void

    @State private var tempStartDate: Date
    @State private var tempEndDate: Date

    init(startDate: Binding<Date?>, endDate: Binding<Date?>, onDismiss: @escaping () -> Void) {
        self._startDate = startDate
        self._endDate = endDate
        self.onDismiss = onDismiss
        // 初始化临时状态，如果外部没有值，则使用当天
        _tempStartDate = State(initialValue: startDate.wrappedValue ?? Date())
        // 如果外部没有结束日期，则默认等于开始日期
        _tempEndDate = State(initialValue: endDate.wrappedValue ?? (startDate.wrappedValue ?? Date()))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("date_picker_title")
                .font(.system(size: 17, weight: .semibold))
                .padding(.top)

            DatePicker(
                "date_picker_start_date",
                selection: $tempStartDate,
                in: Date()..., // Disable past dates
                displayedComponents: .date
            )

            DatePicker(
                "date_picker_end_date",
                selection: $tempEndDate,
                in: tempStartDate..., // End date must be after start date
                displayedComponents: .date
            )
            
            Spacer()
            
            Button("date_picker_done") {
                self.startDate = self.tempStartDate
                self.endDate = self.tempEndDate
                onDismiss()
            }
            .font(.system(size: 17, weight: .regular))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .onChange(of: tempStartDate) {
            // 当开始日期变化时，确保结束日期不会早于它
            if tempEndDate < tempStartDate {
                tempEndDate = tempStartDate
            }
        }
    }
} 