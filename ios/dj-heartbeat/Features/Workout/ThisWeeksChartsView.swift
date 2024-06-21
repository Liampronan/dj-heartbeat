import SwiftUI

struct ThisWeeksChartsHomeRowView: View {
    @Environment(\.weeklyChartProvider) private var weeklyChartProvider
    
    private struct ViewStrings {
        static let emptyStateDescription = "No tracks for this week yet.\nStart a workout to add tracks."
        static let spotifyAttribution = "Metadata powered by"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ThisWeeksChartsTitleView()
                
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .deepPurple.opacity(0.3), radius: 4)
                
                ScrollView {
                    Spacer()
                    chartContentView
                    Spacer(minLength: 30)
                    spotifyAttribution
                    Spacer(minLength: 24)
                }
                .clipShape(.rect(cornerSize: .init(width: 16, height: 16)))
                .foregroundStyle(.white)
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, MVP_DESIGN_SYSTEM_GUTTER)
        .onAppear {
            Task { await weeklyChartProvider.fetchThisWeeksChartData() }
        }
    }
    
    @ViewBuilder private var chartContentView: some View {
        switch weeklyChartProvider.state {
        case .loading:
            VStack {
                ProgressView()
            }.padding(.top, 110)            
        case .error:
            ErrorView()
        case .fetched(_):
            if weeklyChartProvider.selectedWeekChartData.isEmpty {
                VStack {
    //             no idea why Spacers / vertical alignment isn't working here. but this works for now
                    Text("\(ViewStrings.emptyStateDescription)\n\n\n\n")
                        .foregroundStyle(AppColor.gray2)
                        .multilineTextAlignment(.center)
                        .frame(height: 350)
                }
                
            } else {
                VStack {
                    chartItemViews
                }
            }
        }
    }
    
    private var chartItemViews: some View {
        ForEach(Array(weeklyChartProvider.selectedWeekChartData.enumerated()), id: \.element.id) { (index, track) in
            Spacer(minLength: 12)
            ChartItemView(track: track, chartType: .topTracksWeekly(maxHeartbeatThisWeek: maxHBForCurrentWeek))
            Spacer(minLength: 10)
        }
    }

    private var spotifyAttribution: some View {
        HStack(spacing: 16) {
            // only show spotify attribution when metadata is actually there.
            // this mainly helps simplify layout for empty-state case.
            if weeklyChartProvider.selectedWeekChartData.count > 0 {
                Text(ViewStrings.spotifyAttribution)
                    .foregroundStyle(.gray1)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Image(uiImage: .spotifyLogoWithName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                
            }
        }
    }
    
    private var maxHBForCurrentWeek: Int {
        weeklyChartProvider
            .selectedWeekChartData
            .map { $0.heartbeats }.max() ?? 300
    }
}

#Preview {
    ThisWeeksChartsHomeRowView()
        .environment(\.weeklyChartProvider, PreviewWeeklyChartProvider.fetched)
        .frame(maxHeight: 350)
}
