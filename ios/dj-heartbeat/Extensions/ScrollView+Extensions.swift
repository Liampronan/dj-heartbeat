import UIKit

// this is kinda hacky but doesn't seem like a big deal.
// it's goal is to allow the shadows of subviews to fully render outisde scrollviews.
// see: https://www.bam.tech/article/swiftui-why-are-my-shadows-clipped
extension UIScrollView {
    // consider deleting this file once homeview is laid out. this level of hackiness is cursed with side-effects...
//    open override var clipsToBounds: Bool {
//        get { false }
//        set {}
//    }
}
