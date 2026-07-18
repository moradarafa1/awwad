//
//  AwwadWidget.swift
//  AwwadWidget
//
//  iOS twin of Android's AwwadWidgetProvider: active habit name + streak +
//  quick-log button. All texts are PRE-LOCALIZED by the Flutter side
//  (HomeWidgetSync.push writes them to the shared app-group UserDefaults);
//  this file only lays them out. Native logic = the midnight rollover only
//  (data saved yesterday must not show today as already logged).
//

import AppIntents
import SwiftUI
import WidgetKit

let awwadGroupId = "group.com.awwad.awwad"

private func todayKey() -> String {
  let f = DateFormatter()
  f.dateFormat = "yyyy-MM-dd"
  f.locale = Locale(identifier: "en_US_POSIX")
  return f.string(from: Date())
}

struct AwwadEntry: TimelineEntry {
  let date: Date
  let name: String
  let streak: String
  let button: String
  let logged: Bool
}

struct AwwadProvider: TimelineProvider {
  func makeEntry() -> AwwadEntry {
    let d = UserDefaults(suiteName: awwadGroupId)
    let savedDate = d?.string(forKey: "aw_date")
    let logged = (d?.bool(forKey: "aw_logged") ?? false) && savedDate == todayKey()
    return AwwadEntry(
      date: Date(),
      name: d?.string(forKey: "aw_name") ?? "عوّاد",
      streak: d?.string(forKey: "aw_streak") ?? "افتح التطبيق لبدء سلسلتك",
      button: logged
        ? (d?.string(forKey: "aw_btn_done") ?? "سُجّل اليوم")
        : (d?.string(forKey: "aw_btn_log") ?? "سجّل هذا اليوم"),
      logged: logged)
  }

  func placeholder(in context: Context) -> AwwadEntry { makeEntry() }

  func getSnapshot(in context: Context, completion: @escaping (AwwadEntry) -> Void) {
    completion(makeEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AwwadEntry>) -> Void) {
    // Refresh right after local midnight so the logged state rolls over even
    // if the app is never opened.
    let cal = Calendar.current
    let nextMidnight = cal.nextDate(
      after: Date(), matching: DateComponents(hour: 0, minute: 1),
      matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600 * 6)
    completion(Timeline(entries: [makeEntry()], policy: .after(nextMidnight)))
  }
}

struct AwwadWidgetView: View {
  var entry: AwwadEntry

  var body: some View {
    VStack(spacing: 4) {
      Text(entry.name)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(Color(red: 0.93, green: 0.94, blue: 0.96))
        .lineLimit(1)
      Text(entry.streak)
        .font(.system(size: 12))
        .foregroundColor(Color(red: 0.18, green: 0.83, blue: 0.75))
        .lineLimit(1)
      if #available(iOSApplicationExtension 17, *), !entry.logged {
        // Interactive quick log: runs the same Dart background callback as
        // the Android widget, without opening the app.
        Button(
          intent: AwwadQuickLogIntent(
            url: URL(string: "awwad://quicklog"), appGroup: awwadGroupId)
        ) {
          buttonLabel
        }
        .buttonStyle(.plain)
      } else {
        // Logged already (or iOS 16): tapping anywhere opens the app.
        buttonLabel
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .containerBackgroundCompat()
    .widgetURL(URL(string: "awwad://open?homeWidget"))
  }

  private var buttonLabel: some View {
    Text(entry.button)
      .font(.system(size: 12, weight: .bold))
      .foregroundColor(
        entry.logged
          ? Color(red: 0.18, green: 0.83, blue: 0.75)
          : Color(red: 0.04, green: 0.05, blue: 0.08)
      )
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(
        Capsule().fill(
          entry.logged
            ? Color(red: 0.18, green: 0.83, blue: 0.75).opacity(0.15)
            : Color(red: 0.18, green: 0.83, blue: 0.75)))
  }
}

extension View {
  // iOS 17 requires containerBackground; earlier versions use a plain
  // background so one codebase serves both.
  @ViewBuilder
  func containerBackgroundCompat() -> some View {
    if #available(iOSApplicationExtension 17, *) {
      containerBackground(Color(red: 0.07, green: 0.086, blue: 0.12), for: .widget)
    } else {
      background(Color(red: 0.07, green: 0.086, blue: 0.12))
    }
  }
}

struct AwwadWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "AwwadWidget", provider: AwwadProvider()) { entry in
      AwwadWidgetView(entry: entry)
    }
    .configurationDisplayName("عوّاد")
    .description("سلسلتك اليومية وتسجيل سريع ليومك.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
