//
//  SongLikesService.swift
//  music
//
//  Created by Nikolai Golubkin on 11/11/25.
//

import Foundation

// MARK: - API Response Models
struct SongLikeStatusResponse: Codable {
    let isLiked: Bool
    let isDisliked: Bool
    let likesCount: Int
    let dislikesCount: Int
}

struct SongLikeRequest: Codable {
    let userId: String
    let songId: String
}

// MARK: - Song Likes Service
class SongLikesService: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    
    // Base API URL - same as SongsService
    private var baseURL: String {
        return "https://music-back-g2u6.onrender.com"
    }
    
    // MARK: - Like Song
    func likeSong(userId: String, songId: String) async throws {
        let url = URL(string: "\(baseURL)/api/v1/song-likes/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let likeRequest = SongLikeRequest(userId: userId, songId: songId)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(likeRequest)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SongLikesServiceError.likeFailed
        }
    }
    
    // MARK: - Dislike Song
    func dislikeSong(userId: String, songId: String) async throws {
        let url = URL(string: "\(baseURL)/api/v1/song-likes/dislike")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dislikeRequest = SongLikeRequest(userId: userId, songId: songId)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(dislikeRequest)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SongLikesServiceError.dislikeFailed
        }
    }
    
    // MARK: - Get Song Like Status
    func getSongLikeStatus(songId: String, userId: String) async throws -> SongLikeStatusResponse {
        let url = URL(string: "\(baseURL)/api/v1/song-likes/song/\(songId)/user/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SongLikesServiceError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        let status = try decoder.decode(SongLikeStatusResponse.self, from: data)
        
        return status
    }
}

// MARK: - Errors
enum SongLikesServiceError: LocalizedError {
    case likeFailed
    case dislikeFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .likeFailed:
            return "Failed to like song"
        case .dislikeFailed:
            return "Failed to dislike song"
        case .fetchFailed:
            return "Failed to fetch song like status"
        }
    }
}

