import SwiftUI

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

// 自定义日历视图
struct CustomCalendarView: View {
    let month: Date
    @Binding var selectedRange: ClosedRange<Date>?
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let daysInWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 12) {
            // 月份标题 - 增加顶部间距
            Text(formatMonth(month))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.top, 3)
                .padding(.bottom, 5)
            
            // 星期标题
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayView(
                            date: date,
                            isSelected: isDateSelected(date),
                            isInRange: isDateInRange(date),
                            isToday: calendar.isDateInToday(date),
                            isEnabled: date >= Date().startOfDay()
                        ) {
                            onDateSelected(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func getDaysInMonth() -> [Date?] {
        let startOfMonth = calendar.startOfMonth(for: month)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count ?? 0
        
        var days: [Date?] = []
        
        // 添加前一个月的日期（占位符）
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // 添加当前月的日期
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let range = selectedRange else { return false }
        // 只有起始和结束日期被认为是"选中"的
        return calendar.isDate(date, inSameDayAs: range.lowerBound) || 
               calendar.isDate(date, inSameDayAs: range.upperBound)
    }
    
    private func isDateInRange(_ date: Date) -> Bool {
        guard let range = selectedRange else { return false }
        // 范围内的所有日期（包括起始和结束）都显示为选中状态
        return range.contains(date) || 
               calendar.isDate(date, inSameDayAs: range.lowerBound) || 
               calendar.isDate(date, inSameDayAs: range.upperBound)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}

// 单个日期视图
struct DayView: View {
    let date: Date
    let isSelected: Bool
    let isInRange: Bool
    let isToday: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景 - 统一使用相同的蓝色圆圈
                if isSelected || isInRange {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 1)
                        .frame(width: 32, height: 32)
                }
                
                // 日期文字
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
            }
        }
        .buttonStyle(PlainButtonStyle()) // 移除默认的按钮动画
        .disabled(!isEnabled)
        .frame(width: 32, height: 32)
    }
    
    private var textColor: Color {
        if isSelected || isInRange {
            return .white
        } else if !isEnabled {
            return .secondary
        } else {
            return .primary
        }
    }
}

struct DateRangePickerSheet: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.presentationMode) var presentationMode

    let calendar = Calendar.current
    @State private var leftMonth: Date = Date()
    @State private var rightMonth: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var tempStart: Date?
    @State private var tempEnd: Date?
    @State private var selectedRange: ClosedRange<Date>?

    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
    }

    var body: some View {
        NavigationView {
            VStack(spacing: -10) {
                // 第一个月份（上面）
                CustomCalendarView(
                    month: leftMonth,
                    selectedRange: $selectedRange,
                    onDateSelected: handleDateSelection
                )
                
                // 月份导航按钮
                HStack {
                    Button("date_picker_previous_month") {
                        let newLeftMonth = calendar.date(byAdding: .month, value: -1, to: leftMonth) ?? leftMonth
                        let newRightMonth = calendar.date(byAdding: .month, value: -1, to: rightMonth) ?? rightMonth
                        
                        // 确保不会导航到今天之前的月份
                        let today = Date().startOfDay()
                        if newLeftMonth >= calendar.startOfMonth(for: today) {
                            leftMonth = newLeftMonth
                            rightMonth = newRightMonth
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // 移除动画效果
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .regular))
                    
                    Spacer()
                    
                    Button("date_picker_next_month") {
                        leftMonth = calendar.date(byAdding: .month, value: 1, to: leftMonth) ?? leftMonth
                        rightMonth = calendar.date(byAdding: .month, value: 1, to: rightMonth) ?? rightMonth
                    }
                    .buttonStyle(PlainButtonStyle()) // 移除动画效果
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .regular))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                // 第二个月份（下面）
                CustomCalendarView(
                    month: rightMonth,
                    selectedRange: $selectedRange,
                    onDateSelected: handleDateSelection
                )
                
                // Selected Date Range Display
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("date_picker_start_date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(tempStart))
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(tempStart != nil ? .primary : .secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .regular))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("date_picker_end_date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatDate(tempEnd))
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(tempEnd != nil ? .primary : .secondary)
                        }
                    }
                    
                    if let start = tempStart {
                        if let end = tempEnd {
                            // 有开始和结束日期，计算天数
                            let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
                            Text("\(days + 1) \(String(localized: "checklist_days_suffix"))")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                        } else {
                            // 只有开始日期，显示1天
                            Text("1 \(String(localized: "checklist_days_suffix"))")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // 没有选择任何日期，显示0天
                        Text("0 \(String(localized: "checklist_days_suffix"))")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
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
                
                updateSelectedRange()
                
                // 设置初始月份
                let scrollToDate = startDate >= Date().startOfDay() ? startDate : Date()
                leftMonth = scrollToDate
                rightMonth = calendar.date(byAdding: .month, value: 1, to: scrollToDate) ?? scrollToDate
            }
            .navigationBarTitle("date_picker_sheet_title", displayMode: .inline)
            .navigationBarItems(
                leading: Button("date_picker_cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue),
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
                .foregroundColor(.blue)
            )
        }
    }

    private func handleDateSelection(_ date: Date) {
        let selectedDate = date.startOfDay()
        
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
        
        // 更新选中范围
        updateSelectedRange()
    }
    
    private func updateSelectedRange() {
        if let s = tempStart, let e = tempEnd {
            selectedRange = s...e
        } else if let s = tempStart {
            selectedRange = s...s
        } else {
            selectedRange = nil
        }
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
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
} 
 