import SwiftUI

struct NavContainer<Content: View>: View {
    @State private var isShowingProfile = false
    @State private var isShowingAppExplainerView = false
    
    // Capturing the view as a closure allows SwiftUI to defer the view's instantiation until it's actually needed.
    // This can be more efficient, as the view hierarchy inside the closure isn't created at the time of NavContainer's
    // initialization but rather when SwiftUI decides to render the content.
    let content: () -> Content
    
    var body: some View {
        NavigationStack {
            VStack {
                navBarContent
                
                content()
                    .padding(.top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var navBarContent: some View {
        HStack {
            Button(action: {
                isShowingProfile.toggle()
            }) {
                Image(systemName: .gearshape)
            }
            .tint(AppColor.blackText)
            
            Spacer()
            
            CommunityHeartbeatsTickerView()
            
            Button(action: {
                isShowingAppExplainerView.toggle()
            }) {
                Image(systemName: .questionmarkCircle)
            }
            .tint(AppColor.blackText)
        }
        .padding(.horizontal, MVP_DESIGN_SYSTEM_GUTTER / 2)
        .sheet(isPresented: $isShowingProfile, content: {
            ProfileView()
                .presentationDetents([.fraction(0.4)])
        })
        .sheet(isPresented: $isShowingAppExplainerView) {
            AppExplainerView()
                .presentationDetents([.fraction(0.4)])
        }
    }
}

#Preview {
    NavContainer {
        Text("hellooo")
    }.environment(\.weeklyChartProvider, .fetched)
}
