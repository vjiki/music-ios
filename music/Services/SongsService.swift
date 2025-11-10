//
//  SongsService.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import Foundation
import Combine

// MARK: - Protocol (Interface Segregation)
protocol SongsServiceProtocol {
    var songs: [SongsModel] { get }
    var isLoading: Bool { get }
    
    func fetchSongs() async
}

// MARK: - Implementation (Single Responsibility: Songs Fetching)
class SongsService: ObservableObject, SongsServiceProtocol {
    @Published private(set) var songs: [SongsModel] = []
    @Published private(set) var isLoading: Bool = false
    
    private let apiURL = "https://music-back-g2u6.onrender.com/api/v1/songs/user"
    
    init() {
        // Initialize with fallback songs
        self.songs = sampleSongs
    }
    
    func fetchSongs() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            guard let url = URL(string: apiURL) else {
                throw URLError(.badURL)
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Check if response is successful
            guard (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Decode JSON response
            let decoder = JSONDecoder()
            let fetchedSongs = try decoder.decode([SongsModel].self, from: data)
            
            // Check if response is empty
            guard !fetchedSongs.isEmpty else {
                throw SongsServiceError.emptyResponse
            }
            
            await MainActor.run {
                self.songs = fetchedSongs
                self.isLoading = false
            }
            
        } catch {
            // If API fails, use fallback songs
            print("Failed to fetch songs from API: \(error.localizedDescription)")
            print("Using fallback songs from iOS application")
            
            await MainActor.run {
                self.songs = sampleSongs
                self.isLoading = false
            }
        }
    }
}

// MARK: - Errors
enum SongsServiceError: LocalizedError {
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "API returned empty response"
        }
    }
}

