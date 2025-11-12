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
    func toggleLike(_ songID: String, userId: String?) async
    func toggleDislike(_ songID: String, userId: String?) async
    func checkSongLikeStatus(_ songID: String, userId: String?) async
    func getLikedSongs(from songs: [SongsModel]) -> [SongsModel]
    func getDislikedSongs(from songs: [SongsModel]) -> [SongsModel]
}

// MARK: - Implementation (Single Responsibility: User Preferences)
class PreferenceManager: PreferenceManagerProtocol {
    private(set) var likedSongIDs: Set<String> = []
    private(set) var dislikedSongIDs: Set<String> = []
    
    private let songLikesService = SongLikesService()
    
    func isLiked(_ songID: String) -> Bool {
        likedSongIDs.contains(songID)
    }
    
    func isDisliked(_ songID: String) -> Bool {
        dislikedSongIDs.contains(songID)
    }
    
    func toggleLike(_ songID: String, userId: String?) async {
        let wasLiked = likedSongIDs.contains(songID)
        
        // Update local state immediately for responsive UI
        await MainActor.run {
            if wasLiked {
                likedSongIDs.remove(songID)
            } else {
                likedSongIDs.insert(songID)
                dislikedSongIDs.remove(songID)
            }
        }
        
        // Call API if user is authenticated
        if let userId = userId {
            do {
                // Call like endpoint - it should toggle (like if not liked, unlike if liked)
                try await songLikesService.likeSong(userId: userId, songId: songID)
                // Update local state from API response to sync
                let status = try await songLikesService.getSongLikeStatus(songId: songID, userId: userId)
                await MainActor.run {
                    if status.isLiked {
                        likedSongIDs.insert(songID)
                        dislikedSongIDs.remove(songID)
                    } else {
                        likedSongIDs.remove(songID)
                    }
                }
            } catch {
                print("Failed to toggle like: \(error.localizedDescription)")
                // Revert local state on error
                await MainActor.run {
                    if wasLiked {
                        likedSongIDs.insert(songID)
                    } else {
                        likedSongIDs.remove(songID)
                    }
                }
            }
        }
    }
    
    func toggleDislike(_ songID: String, userId: String?) async {
        let wasDisliked = dislikedSongIDs.contains(songID)
        
        // Update local state immediately for responsive UI
        await MainActor.run {
            if wasDisliked {
                dislikedSongIDs.remove(songID)
            } else {
                dislikedSongIDs.insert(songID)
                likedSongIDs.remove(songID)
            }
        }
        
        // Call API if user is authenticated
        if let userId = userId {
            do {
                // Call dislike endpoint - it should toggle (dislike if not disliked, undislike if disliked)
                try await songLikesService.dislikeSong(userId: userId, songId: songID)
                // Update local state from API response to sync
                let status = try await songLikesService.getSongLikeStatus(songId: songID, userId: userId)
                await MainActor.run {
                    if status.isDisliked {
                        dislikedSongIDs.insert(songID)
                        likedSongIDs.remove(songID)
                    } else {
                        dislikedSongIDs.remove(songID)
                    }
                }
            } catch {
                print("Failed to toggle dislike: \(error.localizedDescription)")
                // Revert local state on error
                await MainActor.run {
                    if wasDisliked {
                        dislikedSongIDs.insert(songID)
                    } else {
                        dislikedSongIDs.remove(songID)
                    }
                }
            }
        }
    }
    
    func checkSongLikeStatus(_ songID: String, userId: String?) async {
        guard let userId = userId else {
            return
        }
        
        do {
            let status = try await songLikesService.getSongLikeStatus(songId: songID, userId: userId)
            await MainActor.run {
                if status.isLiked {
                    likedSongIDs.insert(songID)
                    dislikedSongIDs.remove(songID)
                } else if status.isDisliked {
                    dislikedSongIDs.insert(songID)
                    likedSongIDs.remove(songID)
                } else {
                    likedSongIDs.remove(songID)
                    dislikedSongIDs.remove(songID)
                }
            }
        } catch {
            print("Failed to check song like status: \(error.localizedDescription)")
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

