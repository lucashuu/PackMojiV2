import SwiftUI
import ElegantCalendar

// Date 扩展
extension Date {
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}

// Calendar 扩展
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

// 区间高亮数据源
class RangeHighlightMonthlyDataSource: MonthlyCalendarDataSource, ObservableObject {
    var range: ClosedRange<Date>?
    
    func calendar(backgroundColorOpacityForDate date: Date) -> Double {
        if let range = range, range.contains(date) {
            return 0.25 // 减少背景透明度，避免过于显眼
        }
        return 0.0
    }
    
    func calendar(canSelectDate date: Date) -> Bool { 
        return date >= Date().startOfDay() // 只允许选择今天及以后的日期
    }
    
    func calendar(viewForSelectedDate date: Date, dimensions size: CGSize) -> AnyView {
        if let range = range {
            let calendar = Calendar.current
            let isStart = calendar.isDate(date, inSameDayAs: range.lowerBound)
            let isEnd = calendar.isDate(date, inSameDayAs: range.upperBound)
            
            // 只为起始和结束日期添加简单的圆形标记
            if isStart || isEnd {
                return AnyView(
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: min(size.width * 0.7, 24), height: min(size.height * 0.7, 24))
                        
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: min(size.width * 0.35, 12), weight: .medium))
                            .foregroundColor(.white)
                    }
                )
            }
        }
        return AnyView(EmptyView())
    }
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
        
        // 创建自定义配置，减少视觉干扰
        let configuration = CalendarConfiguration(startDate: calendarStart, endDate: calendarEnd)
        
        self.leftManager = MonthlyCalendarManager(configuration: configuration)
        self.rightManager = MonthlyCalendarManager(configuration: configuration)
        
        self.leftManager.datasource = leftDataSource
        self.rightManager.datasource = rightDataSource
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    MonthlyCalendarView(calendarManager: leftManager)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(true)
                        .clipped()
                    MonthlyCalendarView(calendarManager: rightManager)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(true)
                        .clipped()
                }
                HStack {
                    Button("date_picker_previous_month") {
                        let newLeftMonth = calendar.date(byAdding: .month, value: -1, to: leftMonth) ?? leftMonth
                        let newRightMonth = calendar.date(byAdding: .month, value: -1, to: rightMonth) ?? rightMonth
                        
                        // 确保不会导航到今天之前的月份
                        let today = Date().startOfDay()
                        if newLeftMonth >= calendar.startOfMonth(for: today) {
                            leftMonth = newLeftMonth
                            rightMonth = newRightMonth
                            leftManager.scrollToMonth(leftMonth)
                            rightManager.scrollToMonth(rightMonth)
                        }
                    }
                    
                    Spacer()
                    
                    // 显示当前月份
                    VStack(spacing: 2) {
                        Text(formatMonth(leftMonth))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatMonth(rightMonth))
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                
                // Selected Date Range Display
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("date_picker_start_date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(tempStart))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("date_picker_end_date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(tempEnd ?? tempStart))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let start = tempStart, let end = tempEnd {
                        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
                        Text("\(days + 1) \(String(localized: "checklist_days_suffix"))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .onAppear {
                // 设置初始日期范围
                tempStart = startDate.startOfDay()
                tempEnd = endDate.startOfDay()
                
                // 如果开始和结束日期相同，只设置开始日期
                if calendar.isDate(startDate, inSameDayAs: endDate) {
                    tempEnd = nil
                }
                
                updateHighlight()
                
                // 滚动到开始日期或今天
                let scrollToDate = startDate >= Date().startOfDay() ? startDate : Date()
                leftMonth = scrollToDate
                rightMonth = calendar.date(byAdding: .month, value: 1, to: scrollToDate) ?? scrollToDate
                
                // 延迟确保日历视图已准备好
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    leftManager.scrollToMonth(leftMonth)
                    rightManager.scrollToMonth(rightMonth)
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
        let selectedDate = date.startOfDay()
        
        // 立即清除任何默认的选择效果
        DispatchQueue.main.async {
            self.leftManager.selectedDate = nil
            self.rightManager.selectedDate = nil
        }
        
        // 清除之前的高亮
        clearHighlight()
        
        if tempStart == nil || (tempStart != nil && tempEnd != nil) {
            // 开始新的选择或重新选择
            tempStart = selectedDate
            tempEnd = nil
        } else if let start = tempStart {
            if selectedDate >= start {
                // 选择结束日期
                tempEnd = selectedDate
            } else {
                // 选择的日期早于开始日期，重新开始选择
                tempStart = selectedDate
                tempEnd = nil
            }
        }
        
        // 更新高亮
        updateHighlight()
    }

    private func clearHighlight() {
        leftDataSource.range = nil
        rightDataSource.range = nil
        
        // 强制刷新数据源
        DispatchQueue.main.async {
            self.leftDataSource.objectWillChange.send()
            self.rightDataSource.objectWillChange.send()
            
            // 清除日历管理器的选择状态
            self.leftManager.selectedDate = nil
            self.rightManager.selectedDate = nil
        }
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
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { 
            return NSLocalizedString("date_picker_select_date", comment: "Select date placeholder")
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
} 
 