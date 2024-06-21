import FirebaseAuth
import HealthKit
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            ThisWeeksChartsHomeRowView()
            
            Spacer()
            Spacer(minLength: MVP_DESIGN_SYSTEM_GUTTER)
        }
        
    }
}

#Preview {
    HomeView()
        .environment(\.weeklyChartProvider, .fetched)
        .preferredColorScheme(.light)
}
