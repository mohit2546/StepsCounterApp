//
//  StepsWidget.swift
//  StepsWidget
//
//  Created by Mohit on 11/04/25.
//

import WidgetKit
import SwiftUI
import HealthKit

struct Provider: TimelineProvider {
    let healthStore = HKHealthStore()
    
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> ()) {
        // For testing, get real data even in snapshot
        getTimelineEntries { entries in
            completion(entries.first ?? StepsEntry.placeholder)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> ()) {
        getTimelineEntries { entries in
            // Update more frequently during active hours
            let calendar = Calendar.current
            let currentHour = calendar.component(.hour, from: Date())
            
            // Update every 5 minutes during active hours (6 AM to 11 PM)
            // Update every 30 minutes during night hours
            let updateInterval = (currentHour >= 6 && currentHour <= 23) ? 5 : 30
            let nextUpdate = calendar.date(byAdding: .minute, value: updateInterval, to: Date())!
            
            let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func getTimelineEntries(completion: @escaping ([StepsEntry]) -> Void) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.startOfDay(for: endDate)
        let monthStartDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        print("Widget Timeline Update - Start")
        print("Start Date: \(startDate)")
        print("End Date: \(endDate)")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available")
            completion([StepsEntry.placeholder])
            return
        }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        
        let group = DispatchGroup()
        var steps = 0
        var monthlySteps: [Double] = []
        var duration = 0
        
        // Get today's steps
        group.enter()
        let stepsPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let stepsQuery = HKStatisticsQuery(quantityType: stepsType,
                                         quantitySamplePredicate: stepsPredicate) { _, result, error in
            if let error = error {
                print("Steps Query Error: \(error.localizedDescription)")
            }
            if let sum = result?.sumQuantity() {
                steps = Int(sum.doubleValue(for: HKUnit.count()))
                print("Today's Steps: \(steps)")
            } else {
                print("No steps data available")
            }
            group.leave()
        }
        
        // Get monthly average
        group.enter()
        let monthlyPredicate = HKQuery.predicateForSamples(withStart: monthStartDate, end: endDate)
        let monthlyQuery = HKStatisticsCollectionQuery(
            quantityType: stepsType,
            quantitySamplePredicate: monthlyPredicate,
            options: .cumulativeSum,
            anchorDate: monthStartDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        monthlyQuery.initialResultsHandler = { _, results, error in
            if let error = error {
                print("Monthly Query Error: \(error.localizedDescription)")
            }
            if let results = results {
                results.enumerateStatistics(from: monthStartDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let value = sum.doubleValue(for: HKUnit.count())
                        monthlySteps.append(value)
                        print("Day: \(statistics.startDate), Steps: \(value)")
                    }
                }
            } else {
                print("No monthly data available")
            }
            group.leave()
        }
        
        // Get exercise duration
        group.enter()
        let durationPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let durationQuery = HKStatisticsQuery(quantityType: exerciseType,
                                            quantitySamplePredicate: durationPredicate) { _, result, error in
            if let error = error {
                print("Duration Query Error: \(error.localizedDescription)")
            }
            if let sum = result?.sumQuantity() {
                duration = Int(sum.doubleValue(for: HKUnit.minute()))
                print("Today's Duration: \(duration) minutes")
            } else {
                print("No duration data available")
            }
            group.leave()
        }
        
        healthStore.execute(stepsQuery)
        healthStore.execute(monthlyQuery)
        healthStore.execute(durationQuery)
        
        group.notify(queue: .main) {
            let monthlyAverage = monthlySteps.isEmpty ? 0 : Int(monthlySteps.reduce(0, +) / Double(monthlySteps.count))
            print("Monthly Average: \(monthlyAverage)")
            
            let entry = StepsEntry(
                date: endDate,
                steps: steps,
                goal: 12000,
                monthlyAverage: monthlyAverage,
                duration: duration,
                configuration: .circular
            )
            
            completion([entry])
            print("Widget Timeline Update - Complete")
        }
    }
}

struct StepsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var body: some View {
        switch family {
        case .systemSmall:
            CircularStepsWidget(entry: entry)
        case .systemMedium:
            RectangularStepsWidget(entry: entry)
        default:
            RectangularStepsWidget(entry: entry)
        }
    }
}

struct StepsWidgetSmall: Widget {
    private let kind: String = "StepsWidgetSmall"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StepsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Steps Ring")
        .description("Shows your daily steps with a progress ring.")
        .supportedFamilies([.systemSmall])
    }
}

struct StepsWidgetMedium: Widget {
    private let kind: String = "StepsWidgetMedium"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StepsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Steps Stats")
        .description("Shows your steps with monthly average and duration.")
        .supportedFamilies([.systemMedium])
    }
}
