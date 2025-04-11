import Foundation
import HealthKit

@objc(HealthKitManager)
class HealthKitManager: NSObject {
  private let healthStore = HKHealthStore()
  
  @objc
  func requestAuthorization(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    guard HKHealthStore.isHealthDataAvailable() else {
      reject("ERROR", "HealthKit is not available on this device", nil)
      return
    }
    
    let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)!
    let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    let appleExerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
    
    healthStore.requestAuthorization(toShare: [], read: [stepCount, distance, activeEnergy, appleExerciseTime]) { success, error in
      if let error = error {
        reject("ERROR", "Failed to request authorization: \(error.localizedDescription)", error)
        return
      }
      
      resolve(success)
    }
  }
  
  private func getDataForPeriod(
    type: HKQuantityTypeIdentifier,
    startDate: Date,
    endDate: Date,
    interval: DateComponents,
    resolve: @escaping RCTPromiseResolveBlock,
    reject: @escaping RCTPromiseRejectBlock
  ) {
    guard let quantityType = HKObjectType.quantityType(forIdentifier: type) else {
      reject("ERROR", "\(type) type is not available", nil)
      return
    }
    
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    
    let query = HKStatisticsCollectionQuery(
      quantityType: quantityType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: startDate,
      intervalComponents: interval
    )
    
    query.initialResultsHandler = { _, results, error in
      if let error = error {
        reject("ERROR", "Failed to fetch data: \(error.localizedDescription)", error)
        return
      }
      
      guard let results = results else {
        resolve([])
        return
      }
      
      var data: [[String: Any]] = []
      results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
        if let sum = statistics.sumQuantity() {
          let value: Double
          let date = statistics.startDate
          let dateString = ISO8601DateFormatter().string(from: date)
          
          switch type {
          case .stepCount:
            value = sum.doubleValue(for: HKUnit.count())
          case .distanceWalkingRunning:
            value = sum.doubleValue(for: HKUnit.meter())
          case .activeEnergyBurned:
            value = sum.doubleValue(for: HKUnit.kilocalorie())
          case .appleExerciseTime:
            value = sum.doubleValue(for: HKUnit.minute())
          default:
            value = 0
          }
          
          data.append([
            "date": dateString,
            "value": value
          ])
        }
      }
      
      resolve(data)
    }
    
    healthStore.execute(query)
  }
  
  @objc
  func getTodayData(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    
    let group = DispatchGroup()
    var result: [String: Any] = [:]
    var error: Error?
    
    // Steps
    group.enter()
    getDataForPeriod(
      type: .stepCount,
      startDate: startOfDay,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        if let data = data as? [[String: Any]], let first = data.first {
          result["steps"] = first["value"]
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    // Distance
    group.enter()
    getDataForPeriod(
      type: .distanceWalkingRunning,
      startDate: startOfDay,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        if let data = data as? [[String: Any]], let first = data.first {
          result["distance"] = first["value"]
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    // Calories
    group.enter()
    getDataForPeriod(
      type: .activeEnergyBurned,
      startDate: startOfDay,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        if let data = data as? [[String: Any]], let first = data.first {
          result["calories"] = first["value"]
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )

    // Exercise Time
    group.enter()
    getDataForPeriod(
      type: .appleExerciseTime,
      startDate: startOfDay,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        if let data = data as? [[String: Any]], let first = data.first {
          result["duration"] = first["value"]
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    group.notify(queue: .main) {
      if let error = error {
        reject("ERROR", "Failed to fetch data: \(error.localizedDescription)", error)
      } else {
        // Add default goal
        result["stepsGoal"] = 5000
        resolve(result)
      }
    }
  }
  
  @objc
  func getWeeklyData(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let now = Date()
    let startOfWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!
    
    let group = DispatchGroup()
    var result: [String: Any] = [:]
    var error: Error?
    
    // Steps
    group.enter()
    getDataForPeriod(
      type: .stepCount,
      startDate: startOfWeek,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["steps"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["stepsTotal"] = total
          result["stepsAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    // Distance
    group.enter()
    getDataForPeriod(
      type: .distanceWalkingRunning,
      startDate: startOfWeek,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["distance"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["distanceTotal"] = total
          result["distanceAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    // Calories
    group.enter()
    getDataForPeriod(
      type: .activeEnergyBurned,
      startDate: startOfWeek,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["calories"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["caloriesTotal"] = total
          result["caloriesAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )

    // Exercise Time
    group.enter()
    getDataForPeriod(
      type: .appleExerciseTime,
      startDate: startOfWeek,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["duration"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["durationTotal"] = total
          result["durationAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    group.notify(queue: .main) {
      if let error = error {
        reject("ERROR", "Failed to fetch data: \(error.localizedDescription)", error)
      } else {
        resolve(result)
      }
    }
  }
  
  @objc
  func getMonthlyData(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let now = Date()
    let startOfMonth = Calendar.current.date(byAdding: .day, value: -30, to: now)!
    
    let group = DispatchGroup()
    var result: [String: Any] = [:]
    var error: Error?
    
    // Steps
    group.enter()
    getDataForPeriod(
      type: .stepCount,
      startDate: startOfMonth,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["steps"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["stepsTotal"] = total
          result["stepsAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    // Distance
    group.enter()
    getDataForPeriod(
      type: .distanceWalkingRunning,
      startDate: startOfMonth,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["distance"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["distanceTotal"] = total
          result["distanceAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    // Calories
    group.enter()
    getDataForPeriod(
      type: .activeEnergyBurned,
      startDate: startOfMonth,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["calories"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["caloriesTotal"] = total
          result["caloriesAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )

    // Exercise Time
    group.enter()
    getDataForPeriod(
      type: .appleExerciseTime,
      startDate: startOfMonth,
      endDate: now,
      interval: DateComponents(day: 1),
      resolve: { data in
        result["duration"] = data
        if let data = data as? [[String: Any]] {
          let values = data.compactMap { $0["value"] as? Double }
          let total = values.reduce(0, +)
          result["durationTotal"] = total
          result["durationAverage"] = values.isEmpty ? 0 : total / Double(values.count)
        }
        group.leave()
      },
      reject: { code, message, err in
        error = err
        group.leave()
      }
    )
    
    group.notify(queue: .main) {
      if let error = error {
        reject("ERROR", "Failed to fetch data: \(error.localizedDescription)", error)
      } else {
        resolve(result)
      }
    }
  }
  
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  @objc
  static func moduleName() -> String! {
    return "HealthKitManager"
  }
} 