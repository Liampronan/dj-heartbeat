import SwiftUI

struct HomeItem: Identifiable {
    let id = { UUID() }()
    let counter: Int
    let songTitle: String
    let artist: String
    let albumUrl: URL
    let heartbeatsCount: Int
    
    static let mockItems: [HomeItem] = {
        return [
            HomeItem(
                counter: 0,
                songTitle: "Salt Shaker",
                artist: "Ying Yang Twins",
                albumUrl: .init(string: "https://i.scdn.co/image/ab67616d0000b2731f52a7e9b573959c8e430974")!,
                heartbeatsCount: 323
            ),
            HomeItem(counter: 1,
                     songTitle: "Bitch Better Have My Money",
                     artist: "Rihanna",
                     albumUrl: .init(string: "https://i.scdn.co/image/ab67616d0000b273c137319751a89295f921cce8")!,
                     heartbeatsCount: 370
                    ),
            HomeItem(counter: 2, songTitle: "Back to Back",
                     artist: "Drake",
                     albumUrl: .init(string: "https://i.scdn.co/image/ab67616d0000b2733dc98872a3cf00117e4623e5")!,
                     heartbeatsCount: 410
                    )
        ]
    }()
}

struct LikesGeometryEffect : GeometryEffect {
    var time : Double
    var speed = Double.random(in: 100 ... 200)
    var xDirection = Double.random(in:  -0.05 ... 0.05)
    var yDirection = Double.random(in: -Double.pi ...  0)
    
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

struct LikeTapModifier: ViewModifier {
    @State var time = 0.0
    let duration = 1.0
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .foregroundColor(.white)
                .modifier(LikesGeometryEffect(time: time))
                .opacity(time == 1 ? 0 : 1)
        }
        .onAppear {
            withAnimation (.easeOut(duration: duration)) {
                self.time = duration
            }
        }
    }
}
//
//struct LikeHeartExample: View {
//    @State var likes :[LikeView] = []
//        
//        func likeAction () {
//            likes += [LikeView()]
//        }
//        
//        var body: some View {
//            ZStack {
//                Color.black.ignoresSafeArea()
//                ZStack {
//                    
//                    Image(systemName: "heart")
//                        .resizable()
//                        .frame(width: 50, height: 50)
//                        .padding()
//                        .onTapGesture {
//                            likeAction()
//                        }
//                    
//                    
//                    ForEach (likes) { like in
//                        like.image.resizable()
//                            .frame(width: 50, height: 50)
//                            .modifier(LikeTapModifier())
//                            .padding()
//                            .id(like.id)
//                    }.onChange(of: likes) { newValue in
//                        if likes.count > 5 {
//                            likes.removeFirst()
//                        }
//                    }
//                    
//                }.foregroundColor(.white.opacity(0.5))
//                    .offset(x: 0, y: 60)
//            }
//        }
//}


struct LikeIconVM {
    let image = Image(systemName: "heart.fill")
    let id = UUID()
}

let homeItemWidth: Double = 150.0

struct ScrollViewItemView: View {
    let item: HomeItem
    
    var body: some View {
        HStack {
            AsyncImage(url: item.albumUrl, content: { image in
                VStack {
                    image
                        .resizable()
                        .frame(width: homeItemWidth / 2, height: homeItemWidth / 2)
                        .cornerRadius(10)
                        .padding(.vertical, 2)
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("\(item.heartbeatsCount)")
                    }.foregroundStyle(.black)
                }.overlay {
                    LikesHeartModified().opacity(0.0)
                }
                
            }, placeholder: {
                EmptyView()
            })
        }
    }
}

struct HomeHeaderView: View {
    var body: some View {
        VStack {
            Text("saturday afternoon lift")
                .foregroundStyle(.black)
                .font(.title)
                .fontWeight(.heavy)
                .fontDesign(.rounded)
            Text("you mixed crunk with Vanessa Carlton.")
                .multilineTextAlignment(.center)
                .fontDesign(.rounded)
                .foregroundColor(AppColor.gray3)
            Text("for a total of 5,983 heartbeats.")
                .multilineTextAlignment(.center)
                .fontDesign(.rounded)
                .foregroundColor(AppColor.gray3)
        }
    }
}


struct PrototypePostworkoutView: View {
    @State var isHidden = false
    @State var currentItemIndex = -1
    
    @State private var myOffset = CGPoint()

    
    var body: some View {
        VStack {
            HomeHeaderView()
                .scaleEffect(isHidden ? 0.25 : 1.0)
                .offset(isHidden ? CGSize(width: 0, height: 500) : CGSize(width: 0, height: 250))
                .opacity(isHidden ? 0.0 : 1.0)
                .zIndex(100)
            
            OffsetObservingScrollView(axes: .horizontal, offset: $myOffset) {
                HStack(spacing: 20) {
                    Spacer(minLength: 150)
                    ForEach(HomeItem.mockItems) { item in
                        ScrollViewItemView(item: item)
                            .frame(width: homeItemWidth)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.25), radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                            .padding()
                            .scaleEffect(x: (currentItemIndex == item.counter)  ? 2.0 : 1.0, y: (currentItemIndex == item.counter) ? 2.0 : 1.0)
                            .offset(offset(for: item))
                            .onTapGesture {
                                withAnimation {
                                    isHidden.toggle()
                                }
                            }
                    }
                }
                .frame(maxHeight: homeItemWidth * 4)
            }.scrollIndicators(.never)
                .onChange(of: myOffset, { oldValue, newValue in
                    if newValue.x > 20  {
                        withAnimation {
                            isHidden = true
                        }
                    } else {
                        withAnimation {
                            isHidden = false
                        }
                    }
                    
                    if newValue.x > 150 {
                        withAnimation {
                            currentItemIndex = 1
                        }
                    } else if newValue.x > 30 {
                        withAnimation { currentItemIndex = 0 }
                        
                    }
                })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.white)
        .preferredColorScheme(.light)
        }
            
        
    }
    
    func offset(for item: HomeItem) -> CGSize {
        var height: Int
        switch item.counter {
        case 0: height = 200
        case 1: height = 0
        case 2: height = -140
        default: height = 0
        }
        
        return .init(width: 0, height: height)
    }
    
}



#Preview {
    PrototypePostworkoutView()
}


