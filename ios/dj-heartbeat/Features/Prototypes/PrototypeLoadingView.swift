import SwiftUI
// Pickup note: this could be a good alternative: https://github.com/amosgyamfi/open-swiftui-animations?tab=readme-ov-file#incoming-call-animation-symbol-effect-with-variable-color-and-hue-rotation-incomingcallswift

//. ...... have heart in middle; when zoomin, have music notes pop out

// or see FloatingHeartsRepo



struct AppLoadingGeometryEffect : GeometryEffect {
    var time : Double
    var speed = Double.random(in: 300 ... 320)
    var xDirection = Double.random(in:  -0.05 ... 0.05)
    var yDirection = Double.random(in: -Double.pi/6 ...  -Double.pi/8)
    
    var animatableData: Double {
        get { time }
        set { time = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let xTranslation = speed * xDirection
        let yTranslation = speed * sin(yDirection) * time
        let affineTranslation =  CGAffineTransform(translationX: xTranslation, y: yTranslation)
        return ProjectionTransform(affineTranslation)
    }
}

struct AppLoadingModifier: ViewModifier {
    @State var time = 0.0
    let duration = 1.0
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .foregroundColor(.white)
                .modifier(AppLoadingGeometryEffect(time: time))
                .opacity(time == 1 ? 0 : 1)
        }
        .onAppear {
            withAnimation (.easeIn(duration: duration)) {
                self.time = duration
            }
        }
    }
}


struct AppLoadingIconVM: Identifiable, Equatable {
    let image: Image
    let id = UUID()
    
    enum Icon {
        case musicNote
        case heart
        
        var image: Image {
            return switch self {
            case .musicNote: .init(systemName: .musicNote)
            case .heart: .init(systemName: .heartFill)
            }
        }
    }
    
    private static var lastIcon: Icon = .musicNote
    static func generateNextIcon() -> AppLoadingIconVM {
        if lastIcon == .musicNote {
            lastIcon = .heart
        } else {
            lastIcon = .musicNote
        }
        return AppLoadingIconVM(image: lastIcon.image)
    }
}

struct LikesHeartModified: View {
    @State var likes: [AppLoadingIconVM] = []
    
    func likeAction () {
        likes.append(AppLoadingIconVM.generateNextIcon())
    }
    
    var body: some View {
        ZStack {
            
            ForEach (likes, id: \.id) { like in
                like.image.resizable()
                    .frame(width: 25, height: 25)
                    .modifier(AppLoadingModifier())
                    .padding()
                    .id(like.id)
            }
            .onAppear {
                for i in 1...10 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 * Double(i)) {
                        likeAction()
                    }
                }
            }
            .onChange(of: likes) { oldValue, newValue in
                if newValue.count > 5 {
                    likes.removeFirst()
                }
            }
        }
        .onAppear {
            likeAction()
        }
    }
}

struct PrototypeLoadingView: View {
    var body: some View {
        
        ZStack {
            AppColor.deepPurple
            VStack {
               
            }.overlay {
                LikesHeartModified().opacity(1.0)
            }
        }.ignoresSafeArea()
        
        
    }
}

#Preview {
    PrototypeLoadingView()
}
