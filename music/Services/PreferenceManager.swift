//
//  PreferenceManager.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import Foundation

// MARK: - Protocol (Interface Segregation)
protocol PreferenceManagerProtocol {
    var likedSongIDs: Set<String> { get }
    var dislikedSongIDs: Set<String> { get }
    
    func isLiked(_ songID: String) -> Bool
    func isDisliked(_ songID: String) -> Bool
    func toggleLike(_ songID: String)
    func toggleDislike(_ songID: String)
    func getLikedSongs(from songs: [SongsModel]) -> [SongsModel]
    func getDislikedSongs(from songs: [SongsModel]) -> [SongsModel]
}

// MARK: - Implementation (Single Responsibility: User Preferences)
class PreferenceManager: PreferenceManagerProtocol {
    private(set) var likedSongIDs: Set<String> = []
    private(set) var dislikedSongIDs: Set<String> = []
    
    func isLiked(_ songID: String) -> Bool {
        likedSongIDs.contains(songID)
    }
    
    func isDisliked(_ songID: String) -> Bool {
        dislikedSongIDs.contains(songID)
    }
    
    func toggleLike(_ songID: String) {
        if likedSongIDs.contains(songID) {
            likedSongIDs.remove(songID)
        } else {
            likedSongIDs.insert(songID)
            dislikedSongIDs.remove(songID)
        }
    }
    
    func toggleDislike(_ songID: String) {
        if dislikedSongIDs.contains(songID) {
            dislikedSongIDs.remove(songID)
        } else {
            dislikedSongIDs.insert(songID)
            likedSongIDs.remove(songID)
        }
    }
    
    func getLikedSongs(from songs: [SongsModel]) -> [SongsModel] {
        songs.filter { likedSongIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    
    func getDislikedSongs(from songs: [SongsModel]) -> [SongsModel] {
        songs.filter { dislikedSongIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

