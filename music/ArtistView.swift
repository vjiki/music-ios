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
    
    private var artistSongs: [SongsModel] {
        songManager.librarySongs.filter { $0.artist == artistName }
    }
    
    private var popularTracks: [SongsModel] {
        artistSongs.prefix(5).map { $0 }
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
                    
                    // Popular Tracks Section
                    popularTracksSection
                    
                    // All Songs Section
                    allSongsSection
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
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
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 400)
            .ignoresSafeArea()
            
            // Artist photo placeholder
            VStack(spacing: 16) {
                Spacer()
                
                // Artist photo
                Image(systemName: "person.3.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                // Artist name
                Text(artistName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                
                // Listener count
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("40 278 a month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Interaction Buttons
    private var interactionButtons: some View {
        HStack(spacing: 20) {
            // Like button
            VStack(spacing: 8) {
                Button {
                    // Like action
                } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Text("38 490")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // Donate button
            Button {
                // Donate action
            } label: {
                Text("P")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Trailer button
            Button {
                // Trailer action
            } label: {
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
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
                    AsyncImage(url: URL(string: recentRelease.cover)) { image in
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
    
    // MARK: - Popular Tracks Section
    private var popularTracksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular tracks")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 0) {
                ForEach(Array(popularTracks.enumerated()), id: \.element.id) { index, song in
                    PopularTrackRow(
                        index: index + 1,
                        song: song,
                        isActive: song.id == songManager.song.id
                    ) {
                        songManager.playSong(song, in: artistSongs)
                    }
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
        .padding(.bottom, 100)
    }
}

// MARK: - Popular Track Row
private struct PopularTrackRow: View {
    let index: Int
    let song: SongsModel
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Track number
                Text("\(index)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isActive ? .yellow : .white.opacity(0.6))
                    .frame(width: 30, alignment: .leading)
                
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

// MARK: - Song Row
private struct SongRow: View {
    let song: SongsModel
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Album artwork
                AsyncImage(url: URL(string: song.cover)) { image in
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
}

