//
//  HabitGameWidget.swift
//  HabitGameWidget
//
//  Created by Bahaa Najjar on 17/10/1447 AH.
//

import WidgetKit
import SwiftUI

struct HabitGameEntry: TimelineEntry {
    let date: Date
    let completedHabits: Int
    let totalHabits: Int
    let maxStreak: Int
    let waterMl: Int
    let waterGoal: Int
}

struct HabitGameProvider: TimelineProvider {
    let defaults = UserDefaults(suiteName: "group.com.habitgame.widget")

    func placeholder(in context: Context) -> HabitGameEntry {
        HabitGameEntry(date: Date(), completedHabits: 3, totalHabits: 7, maxStreak: 5, waterMl: 1200, waterGoal: 2500)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitGameEntry) -> Void) {
        completion(getEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitGameEntry>) -> Void) {
        let entry = getEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getEntry() -> HabitGameEntry {
        HabitGameEntry(
            date: Date(),
            completedHabits: defaults?.integer(forKey: "completed_habits") ?? 0,
            totalHabits: defaults?.integer(forKey: "total_habits") ?? 0,
            maxStreak: defaults?.integer(forKey: "max_streak") ?? 0,
            waterMl: defaults?.integer(forKey: "water_ml") ?? 0,
            waterGoal: defaults?.integer(forKey: "water_goal") ?? 2500
        )
    }
}

struct HabitGameWidgetEntryView: View {
    var entry: HabitGameProvider.Entry
    @Environment(\.widgetFamily) var family

    var habitProgress: Double {
        guard entry.totalHabits > 0 else { return 0 }
        return Double(entry.completedHabits) / Double(entry.totalHabits)
    }

    var waterProgress: Double {
        guard entry.waterGoal > 0 else { return 0 }
        return min(Double(entry.waterMl) / Double(entry.waterGoal), 1.0)
    }

    var body: some View {
        if family == .systemSmall {
            smallWidget
        } else {
            mediumWidget
        }
    }

    var smallWidget: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(red: 0.804, green: 1.0, blue: 0.0))
                    .font(.system(size: 14))
                Text("\(entry.completedHabits)/\(entry.totalHabits)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if entry.maxStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("\(entry.maxStreak)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.804, green: 1.0, blue: 0.0))
                        .frame(width: geo.size.width * habitProgress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(Color(red: 0.31, green: 0.76, blue: 0.97))
                    .font(.system(size: 14))
                Text("\(entry.waterMl)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("مل")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.31, green: 0.76, blue: 0.97))
                        .frame(width: geo.size.width * waterProgress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(red: 0.051, green: 0.051, blue: 0.051)
        }
    }

    var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.804, green: 1.0, blue: 0.0))
                    Text("العادات")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Text("\(entry.completedHabits)/\(entry.totalHabits)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.804, green: 1.0, blue: 0.0))
                            .frame(width: geo.size.width * habitProgress, height: 6)
                    }
                }
                .frame(height: 6)

                if entry.maxStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        Text("\(entry.maxStreak) يوم")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(Color(red: 0.31, green: 0.76, blue: 0.97))
                    Text("الماء")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                (
                    Text("\(entry.waterMl)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    +
                    Text(" مل")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                )

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.31, green: 0.76, blue: 0.97))
                            .frame(width: geo.size.width * waterProgress, height: 6)
                    }
                }
                .frame(height: 6)

                Text("الهدف: \(entry.waterGoal) مل")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(red: 0.051, green: 0.051, blue: 0.051)
        }
    }
}

struct HabitGameWidget: Widget {
    let kind: String = "HabitGameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitGameProvider()) { entry in
            HabitGameWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("تتبع العادات")
        .description("تابع عاداتك وشرب الماء")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
