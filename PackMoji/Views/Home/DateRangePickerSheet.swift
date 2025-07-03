import SwiftUI
import ElegantCalendar

// 区间高亮数据源
class RangeHighlightMonthlyDataSource: MonthlyCalendarDataSource, ObservableObject {
    var range: ClosedRange<Date>?
    func calendar(backgroundColorOpacityForDate date: Date) -> Double {
        if let range = range, range.contains(date) {
            return 1.0
        }
        return 0.0
    }
    func calendar(canSelectDate date: Date) -> Bool { true }
    func calendar(viewForSelectedDate date: Date, dimensions size: CGSize) -> AnyView { AnyView(EmptyView()) }
}

struct DateRangePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.presentationMode) var presentationMode

    let calendar = Calendar.current
    let calendarStart = Date().addingTimeInterval(-60*60*24*365)
    let calendarEnd = Date().addingTimeInterval(60*60*24*365)

    @ObservedObject var leftDataSource = RangeHighlightMonthlyDataSource()
    @ObservedObject var rightDataSource = RangeHighlightMonthlyDataSource()
    @ObservedObject var leftManager: MonthlyCalendarManager
    @ObservedObject var rightManager: MonthlyCalendarManager
    @State private var leftMonth: Date = Date()
    @State private var rightMonth: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var tempStart: Date?
    @State private var tempEnd: Date?

    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
        let calendarStart = Date().addingTimeInterval(-60*60*24*365)
        let calendarEnd = Date().addingTimeInterval(60*60*24*365)
        self.leftManager = MonthlyCalendarManager(
            configuration: CalendarConfiguration(startDate: calendarStart, endDate: calendarEnd)
        )
        self.rightManager = MonthlyCalendarManager(
            configuration: CalendarConfiguration(startDate: calendarStart, endDate: calendarEnd)
        )
        self.leftManager.datasource = leftDataSource
        self.rightManager.datasource = rightDataSource
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    MonthlyCalendarView(calendarManager: leftManager)
                        .frame(maxWidth: .infinity)
                    MonthlyCalendarView(calendarManager: rightManager)
                        .frame(maxWidth: .infinity)
                }
                HStack {
                    Button("date_picker_previous_month") {
                        leftMonth = calendar.date(byAdding: .month, value: -1, to: leftMonth) ?? leftMonth
                        rightMonth = calendar.date(byAdding: .month, value: -1, to: rightMonth) ?? rightMonth
                        leftManager.scrollToMonth(leftMonth)
                        rightManager.scrollToMonth(rightMonth)
                    }
                    Spacer()
                    Button("date_picker_next_month") {
                        leftMonth = calendar.date(byAdding: .month, value: 1, to: leftMonth) ?? leftMonth
                        rightMonth = calendar.date(byAdding: .month, value: 1, to: rightMonth) ?? rightMonth
                        leftManager.scrollToMonth(leftMonth)
                        rightManager.scrollToMonth(rightMonth)
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            .onAppear {
                tempStart = startDate
                tempEnd = endDate
                updateHighlight()
                
                // Scroll to today's date when the calendar appears
                let today = Date()
                leftMonth = today
                rightMonth = calendar.date(byAdding: .month, value: 1, to: today) ?? today
                
                // Use a small delay to ensure the calendar views are ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    leftManager.scrollToMonth(today)
                    rightManager.scrollToMonth(calendar.date(byAdding: .month, value: 1, to: today) ?? today)
                }
            }
            .onChange(of: leftManager.selectedDate) { oldValue, newValue in
                if let date = newValue { handleDateSelection(date) }
            }
            .onChange(of: rightManager.selectedDate) { oldValue, newValue in
                if let date = newValue { handleDateSelection(date) }
            }
            .navigationBarTitle("date_picker_sheet_title", displayMode: .inline)
            .navigationBarItems(
                leading: Button("date_picker_cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("date_picker_confirm") {
                    if let s = tempStart, let e = tempEnd {
                        startDate = s
                        endDate = e
                    } else if let s = tempStart {
                        startDate = s
                        endDate = s
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    private func handleDateSelection(_ date: Date) {
        if tempStart == nil || (tempStart != nil && tempEnd != nil) {
            tempStart = date
            tempEnd = nil
        } else if let start = tempStart, date > start {
            tempEnd = date
        } else {
            tempStart = date
            tempEnd = nil
        }
        updateHighlight()
    }

    private func updateHighlight() {
        if let s = tempStart, let e = tempEnd {
            leftDataSource.range = s...e
            rightDataSource.range = s...e
        } else if let s = tempStart {
            leftDataSource.range = s...s
            rightDataSource.range = s...s
        } else {
            leftDataSource.range = nil
            rightDataSource.range = nil
        }
        leftDataSource.objectWillChange.send()
        rightDataSource.objectWillChange.send()
    }
} 
 