import SwiftUI
import WidgetKit

/// The home-screen balance (docs/API.md, Home screen widget). The app writes one pre-formatted, pre-translated JSON under
/// `summary` in the App Group (home_widget); this only draws it. No background refresh: timeline `.never`, the app
/// reloads it after a change.
struct Summary: Decodable {
  struct Line: Decodable {
    let text: String
    let amount: String
    let tone: String
  }

  let v: Int
  /// The ≈ total in the home currency, when every currency converts (small shows it alone).
  let total: Line?
  let lines: [Line]
  let empty: String?
  let updated: String?

  static func load() -> Summary? {
    guard let json = UserDefaults(suiteName: "group.dev.nariinfo.evensies")?.string(forKey: "summary"),
      let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(Summary.self, from: data)
  }
}

struct Entry: TimelineEntry {
  let date: Date
  let summary: Summary?
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry { Entry(date: Date(), summary: nil) }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(Entry(date: Date(), summary: Summary.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    completion(Timeline(entries: [Entry(date: Date(), summary: Summary.load())], policy: .never))
  }
}

struct EvensiesWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: Entry

  private let teal = Color(red: 0, green: 0.59, blue: 0.53)

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Evensies").font(.caption).fontWeight(.semibold).foregroundStyle(teal)
      if let s = entry.summary {
        let max = family == .systemSmall ? 2 : 4
        if let total = s.total, family == .systemMedium {
          // The total, and next to it what it is made of.
          HStack(alignment: .top, spacing: 16) {
            balance(total)
            VStack(alignment: .leading, spacing: 2) {
              ForEach(Array(s.lines.prefix(max).enumerated()), id: \.offset) { _, line in
                HStack(spacing: 4) {
                  Text(line.text).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                  Text(line.amount).font(.caption).fontWeight(.semibold).foregroundStyle(tone(line))
                    .lineLimit(1).minimumScaleFactor(0.6).privacySensitive()
                }
              }
            }
          }
        } else if let total = s.total {
          balance(total)
        } else if s.lines.isEmpty {
          Spacer(minLength: 0)
          Text(s.empty ?? "").font(.subheadline).foregroundStyle(.secondary)
        } else if family == .systemMedium {
          // Two columns: four stacked lines would not fit the height and leave the width empty.
          let shown = Array(s.lines.prefix(max))
          Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            ForEach(Array(stride(from: 0, to: shown.count, by: 2)), id: \.self) { i in
              GridRow {
                balance(shown[i])
                if i + 1 < shown.count { balance(shown[i + 1]) }
              }
            }
          }
        } else {
          ForEach(Array(s.lines.prefix(max).enumerated()), id: \.offset) { _, line in balance(line) }
          if s.lines.count > max {
            Text("…").font(.caption).foregroundStyle(.secondary)
          }
        }
        Spacer(minLength: 0)
        if let updated = s.updated {
          Text(updated).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
        }
      } else {
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(.fill.tertiary, for: .widget)
    .widgetURL(URL(string: "evensies://open"))
  }

  private func tone(_ line: Summary.Line) -> Color { line.tone == "owe" ? Color.red : teal }

  private func balance(_ line: Summary.Line) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(line.text).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
      Text(line.amount)
        .font(family == .systemSmall ? .headline : .title3).fontWeight(.semibold)
        .foregroundStyle(tone(line))
        .lineLimit(1).minimumScaleFactor(0.6)
        .privacySensitive()
    }
  }
}

@main
struct EvensiesWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "EvensiesWidget", provider: Provider()) { entry in
      EvensiesWidgetView(entry: entry)
    }
    .configurationDisplayName("Evensies")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
