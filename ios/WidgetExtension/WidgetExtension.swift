import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.macroaize.app"

// MARK: - Adaptive text colors for light/dark mode
/// Primary text: white in dark mode, medium gray in light mode.
private func adaptiveTextColor(_ colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? .white : Color(red: 99/255, green: 99/255, blue: 102/255)
}

/// Secondary text: muted gray in both modes.
private func adaptiveSecondaryColor(_ colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
        ? Color(red: 128/255, green: 134/255, blue: 139/255)
        : Color(red: 142/255, green: 142/255, blue: 147/255)
}

// MARK: - iOS 17 container background helper
extension View {
    @ViewBuilder
    func if_ios17ClearBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.clear, for: .widget)
        } else {
            self
        }
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), calories: 0, carbs: 0, protein: 0, fats: 0, goal: 2000, progress: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let data = UserDefaults.init(suiteName: widgetGroupId)
        let entry = SimpleEntry(
            date: Date(),
            calories: data?.integer(forKey: "calories") ?? 0,
            carbs: data?.integer(forKey: "carbs") ?? 0,
            protein: data?.integer(forKey: "protein") ?? 0,
            fats: data?.integer(forKey: "fats") ?? 0,
            goal: data?.integer(forKey: "goal") ?? 2000,
            progress: data?.integer(forKey: "progress") ?? 0
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(in: context) { entry in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let calories: Int
    let carbs: Int
    let protein: Int
    let fats: Int
    let goal: Int
    let progress: Int
}

struct SmallWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("Daily Progress")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(adaptiveTextColor(colorScheme))
            
            Spacer()
            
            ZStack {
                // Background Ring
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                    .opacity(0.3)
                    .foregroundColor(Color(red: 60/255, green: 64/255, blue: 67/255)) // neutralGrey800
                    .rotationEffect(Angle(degrees: -90.0))
                
                // Progress Ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Double(entry.progress) / 100.0, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color(red: 251/255, green: 116/255, blue: 20/255)) // primaryOrange
                    .rotationEffect(Angle(degrees: -90.0))
                
                VStack(spacing: 0) {
                    Text("\(max(0, entry.goal - entry.calories))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(adaptiveTextColor(colorScheme))
                    Text("Left")
                        .font(.system(size: 10))
                        .foregroundColor(adaptiveSecondaryColor(colorScheme))
                }
            }
            .frame(width: 90, height: 90)
            
            Spacer()
            
            Link(destination: URL(string: "macroaize://log")!) {
                ZStack {
                    Circle()
                        .fill(Color(red: 60/255, green: 64/255, blue: 67/255)) // neutralGrey800
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .padding(8)
        .if_ios17ClearBackground()
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Progress
            VStack {
                Text("Calories")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(adaptiveTextColor(colorScheme))
                
                Spacer()
                
                ZStack {
                    // Background Ring
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 8.0, lineCap: .round, lineJoin: .round))
                        .opacity(0.3)
                        .foregroundColor(Color(red: 60/255, green: 64/255, blue: 67/255))
                        .rotationEffect(Angle(degrees: -90.0))
                    
                    // Progress Ring
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(Double(entry.progress) / 100.0, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 8.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color(red: 251/255, green: 116/255, blue: 20/255))
                        .rotationEffect(Angle(degrees: -90.0))
                    
                    VStack(spacing: 0) {
                        Text("\(max(0, entry.goal - entry.calories))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(adaptiveTextColor(colorScheme))
                        Text("Left")
                            .font(.system(size: 10))
                            .foregroundColor(adaptiveSecondaryColor(colorScheme))
                    }
                }
                .frame(width: 80, height: 80)
                
                Spacer()
            }
            
            // Right: Macros
            VStack(alignment: .leading, spacing: 6) {
                MacroRow(label: "Protein", value: entry.protein, color: Color(red: 255/255, green: 107/255, blue: 107/255), max: 150, icon: "protein", colorScheme: colorScheme)
                MacroRow(label: "Carbs", value: entry.carbs, color: Color(red: 78/255, green: 205/255, blue: 196/255), max: 250, icon: "carb", colorScheme: colorScheme)
                MacroRow(label: "Fats", value: entry.fats, color: Color(red: 255/255, green: 230/255, blue: 109/255), max: 80, icon: "fat", colorScheme: colorScheme)
                
                Link(destination: URL(string: "macroaize://log")!) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 60/255, green: 64/255, blue: 67/255)) // neutralGrey800
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .if_ios17ClearBackground()
    }
}

struct MacroRow: View {
    let label: String
    let value: Int
    let color: Color
    let max: Int
    let icon: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(label): \(value)g")
                    .font(.system(size: 10))
                    .foregroundColor(adaptiveTextColor(colorScheme))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 4)
                            .opacity(0.3)
                            .foregroundColor(Color(red: 60/255, green: 64/255, blue: 67/255))
                            .cornerRadius(2)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(Double(value) / Double(max)) * geometry.size.width, geometry.size.width), height: 4)
                            .foregroundColor(color)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}

struct StreakWidgetEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let disciplineScore: Double
    let isActiveToday: Bool
}

struct StreakWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakWidgetEntry {
        StreakWidgetEntry(date: Date(), streakCount: 5, disciplineScore: 80, isActiveToday: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakWidgetEntry) -> ()) {
        let entry = StreakWidgetEntry(date: Date(), streakCount: 5, disciplineScore: 80, isActiveToday: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let data = UserDefaults.init(suiteName: widgetGroupId)
        let entry = StreakWidgetEntry(
            date: Date(),
            streakCount: data?.integer(forKey: "streak_count") ?? 0,
            disciplineScore: data?.double(forKey: "discipline_score") ?? 0.0,
            isActiveToday: data?.bool(forKey: "is_active_today") ?? false
        )
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct StreakWidgetView: View {
    var entry: StreakWidgetProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("fire")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .padding(.bottom, 8)
            
            Text("\(entry.streakCount)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(adaptiveTextColor(colorScheme))
            
            Text("Day Streak")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(adaptiveSecondaryColor(colorScheme))
        }
        .padding(16)
        .if_ios17ClearBackground()
    }
}


struct MacroaizeSmallWidget: Widget {
    let kind: String = "MacroaizeSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your daily calorie progress at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct MacroaizeLargeWidget: Widget {
    let kind: String = "MacroaizeLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LargeWidgetView(entry: entry)
        }
        .configurationDisplayName("Calories & Macros")
        .description("View calories and macronutrient breakdown.")
        .supportedFamilies([.systemMedium])
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakWidgetProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Streak")
        .description("Keep your flame alive!")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct MacroaizeWidgets: WidgetBundle {
    var body: some Widget {
        MacroaizeSmallWidget()
        MacroaizeLargeWidget()
        StreakWidget()
    }
}
