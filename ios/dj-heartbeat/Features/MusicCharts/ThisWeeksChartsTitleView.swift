import SwiftUI

struct ThisWeeksChartsTitleView: View {
    @Environment(\.weeklyChartProvider) private var weeklyChartDataProvider
    
    private struct ViewStrings {
        static let title = "Top tracks"
        static let weekSuffix = "week"
        static let thisWeekPrefix = "this"
        static let lastWeekPrefix = "last"
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(ViewStrings.title)
                
                HStack(spacing: 0) {
                    animatedCurrentWeekText
                    Text(" \(ViewStrings.weekSuffix)")
                }.background { underline }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray2.opacity(0.6))
            }
            .font(.system(size: 28))
            .fontDesign(.rounded)
            .fontWeight(.bold)
            .foregroundStyle(.blackText)
            .onTapGesture {
                weeklyChartDataProvider.toggleSelectedWeek()
            }
        }
    }
    
    private var currentWeekText: String {
        let firstWord = weeklyChartDataProvider.selectedWeek.isThisWeekSelected ? ViewStrings.thisWeekPrefix : ViewStrings.lastWeekPrefix
        return "\(firstWord)"
    }
    
    private var animatedCurrentWeekText: some View {
        Text(currentWeekText)
            .frame(width: 50)
            .contentTransition(.numericText(countsDown: !weeklyChartDataProvider.selectedWeek.isThisWeekSelected))
            .animation(
                .easeInOut,
                value: currentWeekText
            )
    }
    
    private var underline: some View {
        RoundedRectangle(cornerRadius: 6.0)
            .foregroundStyle(.gray1)
            .offset(y: 15)
            .frame(height: 3.0)
            .padding(.horizontal, 2)
    }
}

#Preview {
    ThisWeeksChartsTitleView()
        .environment(\.weeklyChartProvider, .fetched)
    .padding()
}
