import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.macroaize.app"

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
    
    var body: some View {
        ZStack {
            Color(red: 33/255, green: 38/255, blue: 45/255) // AppColor.darkCard
            
            VStack {
                Text("Daily Progress")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                ZStack {
                    // Background Ring (Horseshoe)
                    Circle()
                        .trim(from: 0.0, to: 0.75)
                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                        .opacity(0.3)
                        .foregroundColor(Color(red: 60/255, green: 64/255, blue: 67/255)) // neutralGrey800
                        .rotationEffect(Angle(degrees: 135.0))
                    
                    // Progress Ring (Horseshoe)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(Double(entry.progress) / 100.0, 1.0)) * 0.75)
                        .stroke(style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color(red: 251/255, green: 116/255, blue: 20/255)) // primaryOrange
                        .rotationEffect(Angle(degrees: 135.0))
                    
                    VStack(spacing: 0) {
                        Text("\(max(0, entry.goal - entry.calories))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Left")
                            .font(.system(size: 8))
                            .foregroundColor(Color(red: 128/255, green: 134/255, blue: 139/255)) // neutralGrey600
                    }
                }
                .frame(width: 85, height: 85)
                .padding(.vertical, 4)
                
                Spacer()
                
                Link(destination: URL(string: "macroaize://log")!) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 60/255, green: 64/255, blue: 67/255)) // neutralGrey800
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
            .padding(8)
        }
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Color(red: 33/255, green: 38/255, blue: 45/255) // AppColor.darkCard
            
            HStack(spacing: 16) {
                // Left: Progress
                VStack {
                    Text("Calories")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    ZStack {
                        // Background Ring (Horseshoe)
                        Circle()
                            .trim(from: 0.0, to: 0.75)
                            .stroke(style: StrokeStyle(lineWidth: 8.0, lineCap: .round, lineJoin: .round))
                            .opacity(0.3)
                            .foregroundColor(Color(red: 60/255, green: 64/255, blue: 67/255))
                            .rotationEffect(Angle(degrees: 135.0))
                        
                        // Progress Ring (Horseshoe)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(Double(entry.progress) / 100.0, 1.0)) * 0.75)
                            .stroke(style: StrokeStyle(lineWidth: 8.0, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Color(red: 251/255, green: 116/255, blue: 20/255))
                            .rotationEffect(Angle(degrees: 135.0))
                        
                        VStack(spacing: 0) {
                            Text("\(max(0, entry.goal - entry.calories))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Left")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 128/255, green: 134/255, blue: 139/255))
                        }
                    }
                    .frame(width: 80, height: 80)
                }
                
                // Right: Macros
                VStack(alignment: .leading, spacing: 6) {
                    MacroRow(label: "Protein", value: entry.protein, color: Color(red: 255/255, green: 107/255, blue: 107/255), max: 150, icon: "circle.grid.cross.fill")
                    MacroRow(label: "Carbs", value: entry.carbs, color: Color(red: 78/255, green: 205/255, blue: 196/255), max: 250, icon: "leaf.fill")
                    MacroRow(label: "Fats", value: entry.fats, color: Color(red: 255/255, green: 230/255, blue: 109/255), max: 80, icon: "drop.fill")
                    
                    Link(destination: URL(string: "macroaize://log")!) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 60/255, green: 64/255, blue: 67/255)) // neutralGrey800
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(12)
        }
    }
}

struct MacroRow: View {
    let label: String
    let value: Int
    let color: Color
    let max: Int
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(label): \(value)g")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                
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
    
    var body: some View {
        ZStack {
            Color(red: 33/255, green: 38/255, blue: 45/255) // AppColor.darkCard
            
            VStack {
                HStack {
                    Image("fire")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                    
                    Spacer()
                    
                    Text("STREAK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 128/255, green: 134/255, blue: 139/255))
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    Text("\(entry.streakCount)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Days")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 128/255, green: 134/255, blue: 139/255))
                        .padding(.bottom, 6)
                    
                    Spacer()
                }
            }
            .padding(16)
        }
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
