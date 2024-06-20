import SwiftUI

struct CommunityHeartbeatsTickerView: View {
    @Environment(\.weeklyChartProvider) private var weeklyChartDataProvider
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(sumMusicalHeartsForCurrentWeek)")
                .fontWeight(.semibold)
                .frame(width: 140)
                .font(.headline)
                .fontDesign(.rounded)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: !weeklyChartDataProvider.selectedWeek.isThisWeekSelected))
                .animation(
                    .easeInOut.delay(0.15),
                    value: sumMusicalHeartsForCurrentWeek
                )
           
            HStack {
                Spacer()
                Text("community heartbeats")
                    .textCase(.uppercase)
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }.frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 6)
        .foregroundStyle(.white)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .frame(width: 200)
        }
    }
    
    
    private var sumMusicalHeartsForCurrentWeek: String {
        let number = weeklyChartDataProvider.selectedWeekSumOfHeartbeats
        guard number > 0 else { return "" }
        return "\(number.formatted())"
    }
}

private struct PreviewHelperButtonView: View {
    @Environment(\.weeklyChartProvider) var weeklyChartDataProvider

    var body: some View {
        Button("Toggle selected week") {
            weeklyChartDataProvider.toggleSelectedWeek()
        }
    }
}

#Preview {
    Group {
        CommunityHeartbeatsTickerView()
        PreviewHelperButtonView()
    }
    .environment(\.weeklyChartProvider, .fetched)
}
