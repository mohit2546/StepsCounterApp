import WidgetKit
import SwiftUI

enum StepsWidgetType: String, CaseIterable, Codable {
    case circular
    case rectangular
}

struct StepsWidgetConfiguration: Codable, Hashable {
    var widgetType: StepsWidgetType
    
    static let circular = StepsWidgetConfiguration(widgetType: .circular)
    static let rectangular = StepsWidgetConfiguration(widgetType: .rectangular)
}

struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let goal: Int
    let monthlyAverage: Int
    let duration: Int
    let configuration: StepsWidgetConfiguration
    
    static let placeholder = StepsEntry(
        date: Date(),
        steps: 10345,
        goal: 12000,
        monthlyAverage: 3456,
        duration: 34,
        configuration: .circular
    )
} 