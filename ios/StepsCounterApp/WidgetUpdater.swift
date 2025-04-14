import Foundation
import WidgetKit

@objc(WidgetUpdater)
class WidgetUpdater: NSObject {
    
    @objc
    static func moduleName() -> String! {
        return "WidgetUpdater"
    }
    
    @objc
    func reloadAllWidgets() {
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @objc
    func reloadStepsWidgets() {
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(ofKind: "StepsWidgetSmall")
            WidgetCenter.shared.reloadTimelines(ofKind: "StepsWidgetMedium")
        }
    }
} 