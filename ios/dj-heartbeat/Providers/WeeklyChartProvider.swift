import SwiftUI

// TODO: move me to use `FetchableDataState` . with conditional conformance for vars
enum WeeklyChartDataState {
    case loading
    case dataFetched(TopTracksResponse)
    case error
    
    var thisWeeksChartData: [WeeklyTopTrack] {
        switch self {
        case .dataFetched(let topChartsResponse):
            return topChartsResponse.thisWeek.topTracks
        default:
            return []
        }
    }
    
    var lastWeeksChartData: [WeeklyTopTrack] {
        switch self {
        case .dataFetched(let topChartsResponse):
            return topChartsResponse.lastWeek.topTracks
        default:
            return []
        }
    }
    
    var thisWeeksSumOfHeartbeats: Int {
        switch self {
        case .dataFetched(let topCharsResponse):
            return Int(topCharsResponse.thisWeek.sumOfAllCountedHearbeats)
        default:
            return 0
        }
    }
    var lastWeeksSumOfHeartbeats: Int {
        switch self {
        case .dataFetched(let topCharsResponse):
            return Int(topCharsResponse.lastWeek.sumOfAllCountedHearbeats)
        default:
            return 0
        }
    }
}

enum ThisWeeksChartsWeekSelection {
    case thisWeek
    case lastWeek
    
    var isThisWeekSelected: Bool { self == .thisWeek }
    
    mutating func toggle() {
        self = isThisWeekSelected ? .lastWeek : .thisWeek
    }
}

protocol WeeklyChartProvider {
    var state: WeeklyChartDataState { get }
    var selectedWeek: ThisWeeksChartsWeekSelection { get set }
    
    func toggleSelectedWeek()
    func fetchThisWeeksChartData() async
}

extension WeeklyChartProvider {
    var selectedWeekSumOfHeartbeats: Int {
        selectedWeek.isThisWeekSelected  ? state.thisWeeksSumOfHeartbeats : state.lastWeeksSumOfHeartbeats
    }
    
    var selectedWeekChartData: [WeeklyTopTrack] {
        selectedWeek.isThisWeekSelected ? state.thisWeeksChartData : state.lastWeeksChartData
    }
}

@Observable class WeeklyChartDataModel: WeeklyChartProvider {
    var state = WeeklyChartDataState.loading
    var selectedWeek = ThisWeeksChartsWeekSelection.thisWeek
    
    func toggleSelectedWeek() {
        selectedWeek.toggle()
    }
    
    func fetchThisWeeksChartData() async {
        do {
            let result = try await TopTracksAPI.getTopCharts()
            state = .dataFetched(result)
        } catch {
            print("error", error)
        }
    }
}

@Observable class PreviewWeeklyChartProvider: WeeklyChartProvider {
    init(state: WeeklyChartDataState, selectedWeek: ThisWeeksChartsWeekSelection) {
        self.state = state
        self.selectedWeek = selectedWeek
    }
    
    var state: WeeklyChartDataState
    
    var selectedWeek: ThisWeeksChartsWeekSelection
    
    func toggleSelectedWeek() { selectedWeek.toggle() }
    
    func fetchThisWeeksChartData() async { }
}

extension WeeklyChartProvider where Self == PreviewWeeklyChartProvider {
    static var loading: Self {
        PreviewWeeklyChartProvider(state: .loading, selectedWeek: .thisWeek)
    }
    
    static var fetched: Self {
        PreviewWeeklyChartProvider(
            state: .dataFetched(.mock()),
            selectedWeek: .thisWeek
        )
    }
}
