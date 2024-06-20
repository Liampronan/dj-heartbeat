import SwiftUI

struct ChartItemView: View {
    enum ChartType: Equatable {
        case topTracksWeekly(maxHeartbeatThisWeek: Int)
        case postWorkout(maxHeartbeatThisWorkout: Int)
        case none
        
        var isPostWorkoutType: Bool {
            return switch self {
            case .postWorkout(_): true
            default: false
            }
        }
        
        var shouldRenderProgressBar: Bool {
            return switch self {
            case .postWorkout(_), .topTracksWeekly(_):
                true
            case .none:
                false
            }
        }
    }
    
    let track: TrackInfoWithHeartbeats
    let chartType: ChartType
    @State var testHeartbeatCount = 100.0
    
    var body: some View {
        VStack(spacing: 0) {
            TrackItemView(track: track)
            if chartType.shouldRenderProgressBar  {
                heartbeatScoreBarContainer
                    .padding(.top, chartType.isPostWorkoutType ? 12 : 0)
            }
        }
    }
    
    var heartbeatScoreBarContainer: some View {
        GeometryReader { geometry in
            Rectangle()
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadii: .init(topLeading: 2, bottomLeading: 2, bottomTrailing: 6, topTrailing: 6)))
                .frame(width: chartBarWidth(using: geometry))
                .shadow(color: .deepPurple.opacity(0.75), radius: 4, y: 2)
                .overlay(alignment: .trailing) {
                    heartbeatScoreCircleSubview.padding(.trailing, 1)
                }
        }
    }
    
    private func chartBarWidth(using geometry: GeometryProxy) -> Double {
        return switch chartType {
        case .topTracksWeekly(let maxHeartbeatThisWeek):
            geometry.size.width * Double(track.heartbeats) / Double(maxHeartbeatThisWeek)
        case .postWorkout(let maxHeartbeatThisWorkout):
            geometry.size.width * Double(track.heartbeats) / Double(maxHeartbeatThisWorkout)
        case .none:
            0.0
        }
    }
    
    private var heartbeatScore: String {
        return switch chartType {
        case .topTracksWeekly(let maxHeartbeatThisWeek):
            "\(Int(100 * Double(track.heartbeats / maxHeartbeatThisWeek)))"
        case .postWorkout:
            "+ \(Int(track.heartbeats)) ♥"
        case .none:
            ""
        }
    }
    
    @ViewBuilder var heartbeatScoreCircleSubview: some View {
        if chartType.isPostWorkoutType {
            ZStack {
                heartbeatScoreShape
                Text(heartbeatScore)
                    .foregroundStyle(chartType.isPostWorkoutType ? .white : .deepPurple)
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        
        EmptyView()
        
    }
    
    var heartbeatScoreShape: some View {
        VStack {
            switch chartType {
            case .topTracksWeekly:
                Circle()
                    .stroke(AppColor.lightPink, style: .init(lineWidth: 3))
                    .fill(.white)
                    .frame(width: 30, height: 30)
                    .shadow(color: .deepPurple.opacity(0.45), radius: 4, y: 2)
            case .postWorkout:
                RoundedRectangle(cornerSize: .init(width: 16, height: 16))
                    .stroke(AppColor.lightPink, style: .init(lineWidth: 3))
                    .fill(AppColor.lightPink)
                    .frame(width: 70, height: 30)
                    .shadow(color: .deepPurple.opacity(0.45), radius: 4, y: 2)
            case .none:
                EmptyView()
            }
        }
    }
}

//#Preview {
//    ChartItemView()
//}
