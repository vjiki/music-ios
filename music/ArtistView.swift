//
//  ArtistView.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import SwiftUI

struct ArtistView: View {
    let artistName: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var songManager: SongManager
    @EnvironmentObject var authService: AuthService
    
    @StateObject private var songsService = SongsService()
    @State private var band: BandResponse?
    @State private var artistSongs: [SongsModel] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    private var artistCoverUrl: String? {
        band?.coverUrl
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Artist Info Section
                    artistInfoSection
                    
                    // Interaction Buttons
                    interactionButtons
                    
                    // Recent Release Section
                    recentReleaseSection
                    
                    // All Songs Section
                    allSongsSection
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await fetchBandData()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        // Search action
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white)
                    }
                    
                    Button {
                        // Menu action
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - Artist Info Section
    private var artistInfoSection: some View {
        VStack(spacing: 0) {
            // Full width artist cover
            if let coverUrl = artistCoverUrl, let url = URL(string: coverUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ZStack {
                        Color.black
                        ProgressView()
                            .tint(.white.opacity(0.6))
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                .clipped()
            } else {
                // Artist photo placeholder
                ZStack {
                    Color.black
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            }
            
            // Artist name
            Text(artistName)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 20)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Interaction Buttons
    private var interactionButtons: some View {
        HStack {
            Spacer()
            
            // Play button
            Button {
                songManager.playPlaylist(artistSongs)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 70, height: 70)
                    .background(Color.yellow)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Recent Release Section
    private var recentReleaseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent release")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
            
            if let recentRelease = artistSongs.first {
                HStack(spacing: 16) {
                    // Album artwork
                    CachedAsyncImage(url: URL(string: recentRelease.cover)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .tint(.white.opacity(0.6))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recentRelease.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        Text("6 August 2025")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Text("single")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                .onTapGesture {
                    songManager.playSong(recentRelease, in: artistSongs)
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - All Songs Section
    private var allSongsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All songs")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
            
            if isLoading {
                ProgressView()
                    .tint(.white.opacity(0.6))
                    .padding()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.3))
                    Text(error)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            } else if artistSongs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No songs found")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 50)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(artistSongs) { song in
                        SongRow(
                            song: song,
                            isActive: song.id == songManager.song.id
                        ) {
                            songManager.playSong(song, in: artistSongs)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Fetch Band Data
    private func fetchBandData() async {
        // Ensure we're on the main actor to safely access environment objects
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Get userId on main actor to ensure environment object is available
        let userId = await MainActor.run {
            authService.currentUserId
        }
        
        do {
            let response = try await songsService.fetchBand(userId: userId, name: artistName, limit: 20)
            
            await MainActor.run {
                if let firstBand = response.items.first {
                    band = firstBand
                    artistSongs = firstBand.songs
                } else {
                    errorMessage = "Artist not found"
                    artistSongs = []
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load artist data. Please try again."
                artistSongs = []
                print("Failed to fetch band: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Song Row
private struct SongRow: View {
    let song: SongsModel
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Album artwork
                CachedAsyncImage(url: URL(string: song.cover)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                        .tint(.white.opacity(0.6))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Like/dislike indicator
                if song.isLiked {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.pink)
                } else if song.isDisliked {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.red)
                }
                
                // Active indicator
                if isActive {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isActive ? Color.white.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ArtistView(artistName: "Scotch")
        .preferredColorScheme(.dark)
        .environmentObject(SongManager())
        .environmentObject(AuthService())
}

