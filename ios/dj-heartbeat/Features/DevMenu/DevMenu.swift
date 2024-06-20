import SwiftUI

struct DevMenu: View {
    @AppStorage("shouldOverrideHomeWithTicker") private var shouldOverrideHomeWithTicker = false
    @AppStorage("shouldShowTickerViewBetter") private var shouldShowTickerViewBetter = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                homeViewSelector
                tickerViewSelector
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .tint(AppColor.deepPurple)
    }
    
    var homeViewSelector: some View {
        HStack {
            Toggle("Override home with ticker", isOn: $shouldOverrideHomeWithTicker)
        }
    }
    
    var tickerViewSelector: some View {
        HStack {
            Toggle("Show ideal ticker view", isOn: $shouldShowTickerViewBetter)
        }
    }
}


#Preview {
    DevMenu()
}
