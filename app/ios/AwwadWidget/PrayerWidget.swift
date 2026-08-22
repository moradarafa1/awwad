//
//  PrayerWidget.swift
//  AwwadWidget
//
//  iOS twin of Android's PrayerWidgetProvider: the next prayer, a LIVE
//  countdown to the adhan, the Hijri date and today's five times. It reads
//  the SAME `pw_*` keys the Android widget reads, written once by the Flutter
//  side (PrayerWidgetSync.push) into the shared app group - so the two
//  platforms cannot drift apart in content, only in chrome.
//
//  The two pieces of native logic mirror Android's exactly, and for the same
//  reasons (see PrayerWidgetProvider.kt):
//    1. The COUNTDOWN is `Text(date, style: .timer)`, the WidgetKit twin of
//       Android's Chronometer in countdown mode: the system ticks it, the app
//       is never woken, and it stays live between timeline reloads.
//    2. The HIJRI DATE is converted here (Calendar .islamicUmmAlQura, the
//       twin of android.icu ISLAMIC_UMALQURA); only the twelve month NAMES
//       are pushed, because a pushed date string would go stale at midnight.
//
//  Lock screen: this widget is the one that carries .accessoryRectangular /
//  .accessoryCircular / .accessoryInline (iOS 16+). Android has no equivalent
//  API on phones, which is the one place the two platforms genuinely differ.
//
//  NOT YET COMPILED: like the rest of ios/, this file waits on a Mac with
//  Xcode (docs/IOS_PARITY_SETUP.md).
//

import SwiftUI
import WidgetKit

// MARK: - Data

struct PrayerSlot {
  let at: Date
  let key: String
  let hhmm: String
}

struct PrayerRowCell {
  let name: String
  let time: String
  let isNext: Bool
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let hijri: String
  let nextLine: String
  let nextName: String
  let nextAt: Date?
  let row: [PrayerRowCell]
  let empty: String?
}

private let pwTeal = Color(red: 0.18, green: 0.83, blue: 0.75)
private let pwBright = Color(red: 0.93, green: 0.94, blue: 0.96)
private let pwMuted = Color(red: 0.58, green: 0.64, blue: 0.72)
private let pwDim = Color(red: 0.80, green: 0.83, blue: 0.88)

// MARK: - Provider

struct PrayerProvider: TimelineProvider {

  private func defaults() -> UserDefaults? { UserDefaults(suiteName: awwadGroupId) }

  /// "epoch|key|HH:mm,..." exactly as Dart encodes it.
  private func slots(_ d: UserDefaults?) -> [PrayerSlot] {
    guard let raw = d?.string(forKey: "pw_times"), !raw.isEmpty else { return [] }
    return
      raw
      .split(separator: ",")
      .compactMap { part -> PrayerSlot? in
        let f = part.split(separator: "|", omittingEmptySubsequences: false)
        guard f.count == 3, let ms = Double(f[0]), ms > 0 else { return nil }
        return PrayerSlot(
          at: Date(timeIntervalSince1970: ms / 1000),
          key: String(f[1]), hhmm: String(f[2]))
      }
      .sorted { $0.at < $1.at }
  }

  /// "fajr=الفجر,..." exactly as Dart encodes it.
  private func names(_ d: UserDefaults?) -> [String: String] {
    guard let raw = d?.string(forKey: "pw_names"), !raw.isEmpty else { return [:] }
    var out: [String: String] = [:]
    for part in raw.split(separator: ",") {
      guard let i = part.firstIndex(of: "=") else { continue }
      let k = String(part[part.startIndex..<i])
      let v = String(part[part.index(after: i)...])
      if !k.isEmpty && !v.isEmpty { out[k] = v }
    }
    return out
  }

  private func hijri(_ date: Date, _ d: UserDefaults?) -> String {
    let months = (d?.string(forKey: "pw_hmonths") ?? "").split(
      separator: "|", omittingEmptySubsequences: false
    ).map(String.init)
    guard months.count == 12 else { return "" }
    var cal = Calendar(identifier: .islamicUmmAlQura)
    cal.timeZone = TimeZone.current
    let c = cal.dateComponents([.year, .month, .day], from: date)
    guard let y = c.year, let m = c.month, let day = c.day, m >= 1, m <= 12
    else { return "" }
    let suffix = (d?.string(forKey: "pw_hsuffix") ?? "").trimmingCharacters(
      in: .whitespaces)
    let line = "\(day) \(months[m - 1]) \(y) \(suffix)".trimmingCharacters(
      in: .whitespaces)
    let city = (d?.string(forKey: "pw_city") ?? "").trimmingCharacters(in: .whitespaces)
    return city.isEmpty ? line : "\(line)  ·  \(city)"
  }

  /// The card as it looks at [moment]. Everything is derived, so the same
  /// function serves the placeholder, the snapshot and every timeline entry.
  func makeEntry(at moment: Date) -> PrayerEntry {
    let d = defaults()
    let all = slots(d)
    let nm = names(d)
    let next = all.first { $0.at > moment }
    let hij = hijri(moment, d)
    guard let next = next, d?.bool(forKey: "pw_has") ?? false else {
      return PrayerEntry(
        date: moment, hijri: hij, nextLine: "", nextName: "", nextAt: nil,
        row: [],
        empty: d?.string(forKey: "pw_empty") ?? "حدّد موقعك من إعدادات الصلاة")
    }
    let name = nm[next.key] ?? next.key
    let label = d?.string(forKey: "pw_next") ?? ""
    // ONE string, so the system's bidi puts an Arabic name on the right and a
    // Latin one on the left with no layout switch (same rule as Android).
    let line = label.isEmpty ? "\(name)  \(next.hhmm)" : "\(label): \(name)  \(next.hhmm)"

    let cal = Calendar.current
    var today: [String: String] = [:]
    for s in all where cal.isDate(s.at, inSameDayAs: moment) { today[s.key] = s.hhmm }
    let order =
      (d?.string(forKey: "pw_order") ?? "").split(separator: ",").map(String.init)
    let keys = order.count == 5 ? order : ["fajr", "dhuhr", "asr", "maghrib", "isha"]
    let row = keys.map {
      PrayerRowCell(
        name: nm[$0] ?? $0, time: today[$0] ?? "--:--", isNext: $0 == next.key)
    }
    return PrayerEntry(
      date: moment, hijri: hij, nextLine: line, nextName: name, nextAt: next.at,
      row: row, empty: nil)
  }

  func placeholder(in context: Context) -> PrayerEntry { makeEntry(at: Date()) }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(makeEntry(at: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void)
  {
    let now = Date()
    var entries = [makeEntry(at: now)]
    // One entry per upcoming prayer (plus the next midnight for the Hijri
    // rollover), so the card rolls over on its own even when the system
    // defers our reload. The countdown itself needs no entries at all.
    for s in slots(defaults()).filter({ $0.at > now }).prefix(8) {
      entries.append(makeEntry(at: s.at.addingTimeInterval(1)))
    }
    if let midnight = Calendar.current.nextDate(
      after: now, matching: DateComponents(hour: 0, minute: 0, second: 5),
      matchingPolicy: .nextTime)
    {
      entries.append(makeEntry(at: midnight))
      entries.sort { $0.date < $1.date }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

// MARK: - Views

struct PrayerWidgetView: View {
  var entry: PrayerEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .systemSmall:
      compact
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackgroundCompat()
        .widgetURL(URL(string: "awwad://prayer"))
    default:
      full
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackgroundCompat()
        .widgetURL(URL(string: "awwad://prayer"))
    }
  }

  @ViewBuilder private var compact: some View {
    VStack(spacing: 2) {
      if let empty = entry.empty {
        Text(empty).font(.system(size: 12)).foregroundColor(pwMuted)
          .multilineTextAlignment(.center)
      } else {
        if !entry.hijri.isEmpty {
          Text(entry.hijri).font(.system(size: 10)).foregroundColor(pwMuted).lineLimit(1)
        }
        Text(entry.nextName).font(.system(size: 14, weight: .bold))
          .foregroundColor(pwBright).lineLimit(1)
        countdown.font(.system(size: 22, weight: .bold)).foregroundColor(pwTeal)
      }
    }
  }

  @ViewBuilder private var full: some View {
    VStack(spacing: 3) {
      if let empty = entry.empty {
        Text(empty).font(.system(size: 13)).foregroundColor(pwMuted)
          .multilineTextAlignment(.center)
      } else {
        if !entry.hijri.isEmpty {
          Text(entry.hijri).font(.system(size: 11)).foregroundColor(pwMuted).lineLimit(1)
        }
        Text(entry.nextLine).font(.system(size: 13, weight: .bold))
          .foregroundColor(pwBright).lineLimit(1)
        countdown.font(.system(size: 24, weight: .bold)).foregroundColor(pwTeal)
        HStack(spacing: 0) {
          ForEach(Array(entry.row.enumerated()), id: \.offset) { _, cell in
            VStack(spacing: 1) {
              Text(cell.name).font(.system(size: 9))
                .foregroundColor(cell.isNext ? pwTeal : pwMuted).lineLimit(1)
              Text(cell.time).font(.system(size: 11))
                .foregroundColor(cell.isNext ? pwTeal : pwDim).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
          }
        }
        .environment(\.layoutDirection, .leftToRight)
      }
    }
  }

  /// The live countdown. `.timer` is ticked by the system, exactly like
  /// Android's Chronometer, so the widget never has to be reloaded for it.
  @ViewBuilder private var countdown: some View {
    if let at = entry.nextAt {
      Text(at, style: .timer).monospacedDigit().lineLimit(1)
    } else {
      Text("")
    }
  }
}

// MARK: - Lock screen (iOS 16+)

@available(iOSApplicationExtension 16.0, *)
struct PrayerAccessoryView: View {
  var entry: PrayerEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .accessoryInline:
      Text(entry.empty ?? entry.nextLine)
    case .accessoryCircular:
      VStack(spacing: 0) {
        Text(entry.nextName).font(.system(size: 10)).lineLimit(1)
        if let at = entry.nextAt {
          Text(at, style: .timer).font(.system(size: 11, weight: .bold))
            .monospacedDigit().lineLimit(1)
        }
      }
    default:  // .accessoryRectangular
      VStack(alignment: .leading, spacing: 1) {
        if !entry.hijri.isEmpty {
          Text(entry.hijri).font(.system(size: 11)).lineLimit(1)
        }
        Text(entry.empty ?? entry.nextLine).font(.system(size: 13, weight: .bold))
          .lineLimit(1)
        if let at = entry.nextAt {
          Text(at, style: .timer).font(.system(size: 15, weight: .bold))
            .monospacedDigit().lineLimit(1)
        }
      }
    }
  }
}

// MARK: - Widget

struct PrayerWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PrayerWidget", provider: PrayerProvider()) { entry in
      if #available(iOSApplicationExtension 16.0, *) {
        PrayerWidgetRouter(entry: entry)
      } else {
        PrayerWidgetView(entry: entry)
      }
    }
    .configurationDisplayName("مواقيت الصلاة")
    .description("الصلاة القادمة والوقت المتبقي على الأذان والتاريخ الهجري.")
    .supportedFamilies(PrayerWidget.families)
  }

  /// Lock-screen families exist only from iOS 16; the home-screen pair is
  /// always supported.
  static var families: [WidgetFamily] {
    var f: [WidgetFamily] = [.systemSmall, .systemMedium]
    if #available(iOSApplicationExtension 16.0, *) {
      f.append(contentsOf: [.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
    return f
  }
}

/// Picks the home-screen or the lock-screen layout for the family in play.
@available(iOSApplicationExtension 16.0, *)
struct PrayerWidgetRouter: View {
  var entry: PrayerEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .accessoryRectangular, .accessoryCircular, .accessoryInline:
      PrayerAccessoryView(entry: entry)
    default:
      PrayerWidgetView(entry: entry)
    }
  }
}
