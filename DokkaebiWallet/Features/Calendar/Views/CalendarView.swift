import SwiftUI

/// 가족 캘린더 탭: 월간·주간·일간 보기 (FR-CAL-01)
struct CalendarView: View {
    @Environment(SessionViewModel.self) private var session
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CalendarViewModel
    private let formatting = DateFormatting()

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: CalendarViewModel(dependencies: dependencies))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: DWSpacing.cardGap) {
                if viewModel.isUsingMockData { MockDataBanner() }
                DWSegmentedControl(options: CalendarDisplayMode.allCases, selection: $viewModel.mode) { $0.displayName }
                PeriodNavigator(title: viewModel.title,
                                onPrevious: { viewModel.move(by: -1) },
                                onNext: { viewModel.move(by: 1) })

                switch viewModel.mode {
                case .month:
                    MonthGrid(viewModel: viewModel)
                case .week:
                    WeekStrip(viewModel: viewModel)
                case .day:
                    EmptyView()
                }

                if let error = viewModel.error {
                    DWErrorView(error: error) { Task { await reload() } }.dwCardBackground()
                } else {
                    DayEventsCard(title: formatting.dayLabel(viewModel.selectedDate),
                                  events: viewModel.eventsOnSelectedDate,
                                  formatting: formatting) {
                        router.present(.comingSoon(feature: "일정 등록"))
                    }
                }
            }
            .dwScreenPadding()
            .padding(.bottom, DWSpacing.xxl)
            .animation(DWMotion.standard, value: viewModel.mode)
        }
        .dwScreenBackground()
        .dwNavigationStyle("캘린더")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("오늘") { viewModel.goToToday() }
                    .accessibilityHint("오늘 날짜로 이동")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.present(.comingSoon(feature: "일정 등록")) } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("일정 추가")
            }
        }
        .refreshable { await reload() }
        .task(id: session.groupRevision) { await reload() }
        .onChange(of: viewModel.displayedMonth) { Task { await reload() } }
        .accessibilityIdentifier("screen.calendar")
    }

    private func reload() async {
        guard let group = session.currentGroup else { return }
        await viewModel.load(groupID: group.id)
    }
}

private struct WeekdayHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(CalendarViewModel.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol)
                    .dwFont(.caption, color: index == 0 ? DWColor.danger : DWColor.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct MonthGrid: View {
    let viewModel: CalendarViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: DWSpacing.sm) {
            WeekdayHeader()
            LazyVGrid(columns: columns, spacing: DWSpacing.xs) {
                ForEach(viewModel.monthGrid) { day in
                    DayCell(day: day, isSelected: viewModel.isSelected(day)) {
                        withAnimation(DWMotion.quick) { viewModel.select(day.date) }
                    }
                }
            }
        }
        .padding(DWSpacing.md)
        .dwCardBackground()
    }
}

private struct WeekStrip: View {
    let viewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: DWSpacing.sm) {
            WeekdayHeader()
            HStack(spacing: 0) {
                ForEach(viewModel.weekDays) { day in
                    DayCell(day: day, isSelected: viewModel.isSelected(day), dimsOutsideMonth: false) {
                        withAnimation(DWMotion.quick) { viewModel.select(day.date) }
                    }
                }
            }
        }
        .padding(DWSpacing.md)
        .dwCardBackground()
    }
}

/// 날짜 칸 (DESIGN_SYSTEM.md §5 CalendarDayCell)
private struct DayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    var dimsOutsideMonth = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(day.dayNumber)")
                    .font(.system(.callout, weight: day.isToday || isSelected ? .bold : .regular).monospacedDigit())
                    .foregroundStyle(numberColor)
                    .frame(width: 34, height: 34)
                    .background {
                        if day.isToday {
                            Circle().fill(DWColor.primary)
                        } else if isSelected {
                            Circle().fill(DWColor.primarySoft)
                        }
                    }
                HStack(spacing: 2) {
                    ForEach(Array(day.eventColors.enumerated()), id: \.offset) { _, color in
                        Circle().fill(Color(palette: color)).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: DWSpacing.minTouchTarget + 4)
            .contentShape(Rectangle())
            .opacity(dimsOutsideMonth && !day.isInDisplayedMonth ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var numberColor: Color {
        if day.isToday { return DWColor.onPrimary }
        if isSelected { return DWColor.primary }
        if day.isSunday { return DWColor.danger }
        return DWColor.textPrimary
    }

    private var accessibilityText: String {
        var text = "\(day.dayNumber)일"
        if day.isToday { text += ", 오늘" }
        if !day.eventColors.isEmpty { text += ", 일정 \(day.eventColors.count)개" }
        return text
    }
}

private struct DayEventsCard: View {
    let title: String
    let events: [CalendarEvent]
    let formatting: DateFormatting
    let onAdd: () -> Void

    var body: some View {
        DWCard(title: title) {
            if events.isEmpty {
                DWEmptyState(systemImage: "calendar", title: "오늘은 여유로운 하루예요",
                             message: "가족 일정을 등록하면 함께 볼 수 있어요",
                             actionTitle: "일정 추가", action: onAdd)
            } else {
                VStack(alignment: .leading, spacing: DWSpacing.md) {
                    ForEach(events) { event in
                        EventRow(event: event, timeText: event.isAllDay ? "종일" :
                                 "\(formatting.time(event.startsAt)) - \(formatting.time(event.endsAt))")
                    }
                }
            }
        }
    }
}

#Preview("캘린더") {
    PreviewHost { CalendarView(dependencies: $0.dependencies) }
}
