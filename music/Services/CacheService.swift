//
//  CacheService.swift
//  music
//
//  Created by Nikolai Golubkin on 11/11/25.
//

import Foundation
import SwiftUI

class CacheService: ObservableObject {
    static let shared = CacheService()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let imagesCacheDirectory: URL
    private let audioCacheDirectory: URL
    
    @Published private(set) var totalCacheSize: Double = 0.0 // GB
    @Published private(set) var imagesCacheSize: Double = 0.0 // GB
    @Published private(set) var audioCacheSize: Double = 0.0 // GB
    
    private init() {
        // Get cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent("MusicAppCache")
        imagesCacheDirectory = cacheDirectory.appendingPathComponent("Images")
        audioCacheDirectory = cacheDirectory.appendingPathComponent("Audio")
        
        // Create directories if they don't exist
        createDirectoriesIfNeeded()
        
        // Calculate initial cache size
        Task {
            await calculateCacheSize()
        }
    }
    
    // MARK: - Directory Setup
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imagesCacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: audioCacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Image Caching
    func cacheImage(url: URL, data: Data) {
        let fileName = url.absoluteString.md5 + ".jpg"
        let fileURL = imagesCacheDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
        
        Task {
            await calculateCacheSize()
        }
    }
    
    func getCachedImage(url: URL) -> UIImage? {
        let fileName = url.absoluteString.md5 + ".jpg"
        let fileURL = imagesCacheDirectory.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return UIImage(data: data)
    }
    
    func hasCachedImage(url: URL) -> Bool {
        let fileName = url.absoluteString.md5 + ".jpg"
        let fileURL = imagesCacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Audio Caching
    func cacheAudio(url: URL, data: Data) {
        let fileName = url.absoluteString.md5 + ".mp3"
        let fileURL = audioCacheDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
        
        Task {
            await calculateCacheSize()
        }
    }
    
    func getCachedAudioURL(url: URL) -> URL? {
        let fileName = url.absoluteString.md5 + ".mp3"
        let fileURL = audioCacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return fileURL
    }
    
    func hasCachedAudio(url: URL) -> Bool {
        let fileName = url.absoluteString.md5 + ".mp3"
        let fileURL = audioCacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Cache Size Calculation
    func calculateCacheSize() async {
        let imagesSize = await calculateDirectorySize(url: imagesCacheDirectory)
        let audioSize = await calculateDirectorySize(url: audioCacheDirectory)
        
        await MainActor.run {
            self.imagesCacheSize = imagesSize
            self.audioCacheSize = audioSize
            self.totalCacheSize = imagesSize + audioSize
        }
    }
    
    private func calculateDirectorySize(url: URL) async -> Double {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0.0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        // Convert bytes to GB
        return Double(totalSize) / (1024.0 * 1024.0 * 1024.0)
    }
    
    // MARK: - Clear Cache
    func clearAllCache() async {
        await clearDirectory(url: imagesCacheDirectory)
        await clearDirectory(url: audioCacheDirectory)
        await calculateCacheSize()
    }
    
    func clearImagesCache() async {
        await clearDirectory(url: imagesCacheDirectory)
        await calculateCacheSize()
    }
    
    func clearAudioCache() async {
        await clearDirectory(url: audioCacheDirectory)
        await calculateCacheSize()
    }
    
    private func clearDirectory(url: URL) async {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Get Cache Statistics
    func getCacheStatistics() -> CacheData {
        let totalSize = totalCacheSize
        let imagesPercentage = totalSize > 0 ? (imagesCacheSize / totalSize) * 100 : 0
        let audioPercentage = totalSize > 0 ? (audioCacheSize / totalSize) * 100 : 0
        
        var categories: [CacheCategory] = []
        
        if imagesCacheSize > 0 {
            categories.append(CacheCategory(
                name: "Photos",
                size: imagesCacheSize,
                percentage: imagesPercentage,
                color: .cyan
            ))
        }
        
        if audioCacheSize > 0 {
            categories.append(CacheCategory(
                name: "Music",
                size: audioCacheSize,
                percentage: audioPercentage,
                color: .red
            ))
        }
        
        // Add "Other" category if there's any remaining space
        let otherSize = totalSize - imagesCacheSize - audioCacheSize
        if otherSize > 0.001 { // 1 MB threshold
            let otherPercentage = (otherSize / totalSize) * 100
            categories.append(CacheCategory(
                name: "Other",
                size: otherSize,
                percentage: otherPercentage,
                color: .orange
            ))
        }
        
        return CacheData(totalSize: totalSize, categories: categories)
    }
}

// MARK: - String Hash Extension
extension String {
    var md5: String {
        // Create a safe filename from URL string
        // Replace invalid characters with underscores
        let invalidChars = CharacterSet(charactersIn: "/:?=&%")
        let safeString = self.components(separatedBy: invalidChars).joined(separator: "_")
        // Use hash for uniqueness
        let hash = abs(safeString.hash)
        return "\(hash)_\(safeString.prefix(50))"
    }
}

