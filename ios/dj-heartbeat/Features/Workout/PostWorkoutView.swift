import SwiftUI

struct PostWorkoutView: View {
    let handleWorkoutResponse: HandleWorkoutResponse
    private struct ViewStrings {
        static let title = "Post workout stats"
        static let hearbeatsSuffix = "musical heartbeats"
    }
    var body: some View {
        VStack {
            ScrollView {
                Spacer()
                titleAndSubtitle
                    .padding(.leading, MVP_DESIGN_SYSTEM_GUTTER)
                    .padding(.top, MVP_DESIGN_SYSTEM_GUTTER)
                Spacer()
                ForEach(handleWorkoutResponse.userListens) { listen in
                    Spacer(minLength: 12)
                    ChartItemView(
                        track: listen,
                        chartType: .postWorkout(maxHeartbeatThisWorkout: handleWorkoutResponse.maxSongHeartbeatsDuringThisWorkout)
                    ).padding(.horizontal, MVP_DESIGN_SYSTEM_GUTTER)
                    
                    Spacer(minLength: 10)
                }
                Spacer()
            }.scrollIndicators(.never)
        }
    }
    
    private var titleAndSubtitle: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ViewStrings.title)
            }
            .font(.system(size: 28))
            .fontDesign(.rounded)
            .fontWeight(.bold)
            .foregroundStyle(.blackText)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(displayableMusicalHeartbeats) \(ViewStrings.hearbeatsSuffix).")
                .font(.body)
                .fontDesign(.rounded)
                .fontWeight(.regular)
                .foregroundStyle(.gray3)
            
        }
    }
    
    private var displayableMusicalHeartbeats: String {
        let number = Int(handleWorkoutResponse.userListens.reduce(into: 0) { $0 += $1.heartbeats })
        return number == 0 ? "No" : "\(number)"
    }
}

let mockHandleWorkoutResponse = HandleWorkoutResponse(userListens: UserListen.mocks + UserListen.mocks)

#Preview {
    VStack {
        PostWorkoutView(handleWorkoutResponse: mockHandleWorkoutResponse)
    }
    
}
