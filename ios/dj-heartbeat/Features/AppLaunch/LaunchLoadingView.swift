import SwiftUI

struct LaunchLoadingView: View {
    var body: some View {
        VStack {
            AppColor
                .lightPurple
                .ignoresSafeArea(edges: .all)
        }
    }
}

#Preview {
    LaunchLoadingView()
}
