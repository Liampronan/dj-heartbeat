//
//  AsyncImageView.swift
//  dj-heartbeat
//
//  Created by Liam Ronan on 6/10/24.
//

import SwiftUI

struct AsyncImageView: View {
    let url: URL
    let heightWidth: CGFloat
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .frame(
                        width: heightWidth,
                        height: heightWidth
                    )
                    .cornerRadius(4)
                    .padding(.vertical, 2)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 1, y: 3)
            } else {
                placeholder
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private var placeholder: some View {
        Rectangle()
            .foregroundStyle(AppColor.lightPurple)
            .frame(width: heightWidth, height: heightWidth)
            .cornerRadius(4)
            .padding(.vertical, 2)
    }
    
    private func loadImage() async {
        if let cachedImage =  ImageCache.shared.image(forKey: url) {
            image = cachedImage
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let downloadedImage = UIImage(data: data) else { return }
            ImageCache.shared.insertImage(downloadedImage, for: url)
            image = downloadedImage
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}
