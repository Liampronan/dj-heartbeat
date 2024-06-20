import UIKit

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSURL, UIImage>()
    
    func image(forKey key: URL) -> UIImage? {
        cache.object(forKey: key as NSURL)
    }
    
    func insertImage(_ image: UIImage?, for key: URL) {
        guard let image = image else {
            cache.removeObject(forKey: key as NSURL)
            return
        }
        cache.setObject(image, forKey: key as NSURL)
    }
}
