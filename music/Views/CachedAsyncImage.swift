//
//  CachedAsyncImage.swift
//  music
//
//  Created by Nikolai Golubkin on 11/11/25.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @StateObject private var loader = ImageLoader()
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            if let url = url {
                loader.load(url: url)
            }
        }
    }
}

private class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let cacheService = CacheService.shared
    
    func load(url: URL) {
        // Check cache first
        if let cachedImage = cacheService.getCachedImage(url: url) {
            self.image = cachedImage
            return
        }
        
        // Load from network
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let uiImage = UIImage(data: data) {
                    // Cache the image
                    cacheService.cacheImage(url: url, data: data)
                    
                    await MainActor.run {
                        self.image = uiImage
                    }
                }
            } catch {
                print("Failed to load image: \(error.localizedDescription)")
            }
        }
    }
}

