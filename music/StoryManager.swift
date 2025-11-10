//
//  StoryManager.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import SwiftUI

class StoryManager: ObservableObject {
    @Published private(set) var stories: [MusicStory] = []
    @Published private(set) var userStories: [MusicStory] = []
    
    private let currentUserId = "current_user"
    private let currentUserName = "You"
    private let currentUserProfileImage: String? = nil
    
    init(songs: [SongsModel] = sampleSongs) {
        loadStories(from: songs)
    }
    
    func createStory(with song: SongsModel) {
        let newStory = MusicStory(
            userId: currentUserId,
            userName: currentUserName,
            profileImageURL: currentUserProfileImage,
            song: song,
            timestamp: Date(),
            isViewed: false
        )
        
        userStories.insert(newStory, at: 0)
        stories.insert(newStory, at: 0)
        
        // Keep only last 24 hours of stories
        let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        userStories = userStories.filter { $0.timestamp > dayAgo }
        stories = stories.filter { $0.timestamp > dayAgo }
    }
    
    func markStoryAsViewed(_ storyId: String) {
        if let index = stories.firstIndex(where: { $0.id == storyId }) {
            let story = stories[index]
            let updated = MusicStory(
                id: story.id,
                userId: story.userId,
                userName: story.userName,
                profileImageURL: story.profileImageURL,
                song: story.song,
                timestamp: story.timestamp,
                isViewed: true
            )
            stories[index] = updated
        }
        
        if let index = userStories.firstIndex(where: { $0.id == storyId }) {
            let story = userStories[index]
            let updated = MusicStory(
                id: story.id,
                userId: story.userId,
                userName: story.userName,
                profileImageURL: story.profileImageURL,
                song: story.song,
                timestamp: story.timestamp,
                isViewed: true
            )
            userStories[index] = updated
        }
    }
    
    var hasUnviewedStories: Bool {
        userStories.contains { !$0.isViewed }
    }
    
    func updateStories(from songs: [SongsModel]) {
        loadStories(from: songs)
    }
    
    private func loadStories(from songs: [SongsModel]) {
        // Sample stories for demo
        let sampleStories = songs.prefix(5).enumerated().map { index, song in
            MusicStory(
                userId: "user_\(index)",
                userName: "User \(index + 1)",
                profileImageURL: song.cover,
                song: song,
                timestamp: Date().addingTimeInterval(-Double(index) * 3600),
                isViewed: index > 2
            )
        }
        
        stories = sampleStories
    }
}

