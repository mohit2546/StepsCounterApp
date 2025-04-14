//
//  StepsWidgetBundle.swift
//  StepsWidget
//
//  Created by Mohit on 11/04/25.
//

import WidgetKit
import SwiftUI

@main
struct StepsWidgetBundle: WidgetBundle {
    var body: some Widget {
        StepsWidgetSmall()
        StepsWidgetMedium()
        StepsWidgetLiveActivity()
        StepsWidgetControl()
    }
}
