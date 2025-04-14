import SwiftUI
import WidgetKit

struct CircularStepsWidget: View {
    let entry: StepsEntry
    
    var progress: Double {
        min(Double(entry.steps) / Double(entry.goal), 1.0)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Background ring
            Circle()
                .stroke(Color(.systemGray6).opacity(0.3), lineWidth: 20)
                .padding(10)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(red: 229/255, green: 255/255, blue: 68/255), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(10)
            
            // Steps count
            Text("\(entry.steps)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(red: 229/255, green: 255/255, blue: 68/255))
                .minimumScaleFactor(0.5)
        }
        .widgetBackground(Color.black)
    }
}

struct RectangularStepsWidget: View {
    let entry: StepsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEPS")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Text("\(entry.steps)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(red: 229/255, green: 255/255, blue: 68/255))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(entry.monthlyAverage)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 229/255, green: 255/255, blue: 68/255))
                    Text("monthly average")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(entry.duration)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 229/255, green: 255/255, blue: 68/255))
                    Text("min")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .widgetBackground(Color.black)
    }
}

// Extension to handle widget background color
extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(color, for: .widget)
        } else {
            return background(color)
        }
    }
} 