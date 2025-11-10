//
//  ContentView.swift
//  music
//
//  Created by Nikolai Golubkin on 15. 8. 2025..
//

import SwiftUI

struct Home: View {
    @EnvironmentObject var songManager: SongManager
    @StateObject private var storyManager = StoryManager()
    @State private var showStoryCreation = false
    @State private var showMessages = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                instagramTopBar
                    .padding(.top, getSafeAreaTop())
                    .padding(.bottom, 16)
                
                heroSection
                
                TagsView()
                
                QuickPlay()
                
                MixesSection()
            }
            .padding(.bottom, 200)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showStoryCreation) {
            StoryCreationView(storyManager: storyManager, songManager: songManager)
        }
        .sheet(isPresented: $showMessages) {
            MessagesView()
        }
    }
    
    private var heroSection: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.32, blue: 0.73),
                    Color(red: 0.62, green: 0.18, blue: 0.94),
                    Color(red: 0.13, green: 0.02, blue: 0.20)
                ],
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                Button {
                    if let first = sampleSongs.first {
                        songManager.playSong(first, in: sampleSongs)
                    }
                } label: {
                    VStack(spacing: 16) {
                        Label {
                            Text("My Vibe")
                                .font(.system(size: 36, weight: .bold))
                                .tracking(1.4)
                        } icon: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        
                        Text("Breathe with me")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.22), in: Capsule())
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                DiscoverRow()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
        }
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .shadow(color: Color.purple.opacity(0.45), radius: 30, x: 0, y: 20)
    }
    
    private var instagramTopBar: some View {
        VStack(spacing: 12) {
            // Header with action buttons
            HStack(spacing: 16) {
                Text("Music")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    songManager.toggleDislike()
                } label: {
                    Image(systemName: songManager.isCurrentSongDisliked ? "heart.slash.fill" : "heart.slash")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(songManager.isCurrentSongDisliked ? .red : .white)
                }
                .buttonStyle(.plain)
                
                Button {
                    songManager.toggleLike()
                } label: {
                    Image(systemName: songManager.isCurrentSongLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(songManager.isCurrentSongLiked ? .red : .white)
                }
                .buttonStyle(.plain)
                
                Button {
                    showMessages = true
                } label: {
                    Image(systemName: "message")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            
            // Stories section
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Your story (create new)
                    Button {
                        showStoryCreation = true
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.pink, Color.orange, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 66, height: 66)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.3))
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .offset(x: 24, y: 24)
                            }
                            
                            Text("Your story")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Other stories
                    ForEach(storyManager.stories) { story in
                        StoryCircleView(story: story) {
                            storyManager.markStoryAsViewed(story.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    @ViewBuilder
    private func DiscoverRow() -> some View {
        HStack(spacing: 16) {
            discoverCard(
                title: "For You",
                subtitle: "Tailored tracks",
                icon: "person.2.fill"
            ) {
                if let first = sampleSongs.first {
                    songManager.playSong(first, in: sampleSongs)
                }
            }
            
            discoverCard(
                title: "Trends",
                subtitle: "What's hot now",
                icon: "flame.fill"
            ) {
                if let randomSong = sampleSongs.randomElement() {
                    songManager.playSong(randomSong, in: sampleSongs.shuffled())
                }
            }
        }
    }
    
    private func discoverCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.caption)
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.7))
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
    
    // Tags View
    @ViewBuilder func TagsView() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Genres & moods")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(sampleTagList, id: \.id) { item in
                        Text(item.tag)
                            .font(.subheadline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    
    // Quick Play Songs
    @ViewBuilder func QuickPlay() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Play")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button("See all") { }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 18) {
                    ForEach(sampleSongs, id: \.id) { item in
                        Button {
                            songManager.playSong(item, in: sampleSongs)
                        } label: {
                            HStack(spacing: 14) {
                                AsyncImage(url: URL(string: item.cover)) { img in
                                    img.resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    
                                    Text(item.artist)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 18)
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }
    
    // Mixes / New Releases Section
    @ViewBuilder func MixesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mixes")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    if let first = sampleSongs.first {
                        songManager.playSong(first, in: sampleSongs)
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(sampleSongs, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 12) {
                            AsyncImage(url: URL(string: item.cover)) { img in
                                img.resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 180, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                
                                Text(item.artist)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 180, alignment: .leading)
                        .padding(16)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 12)
                        .onTapGesture {
                            songManager.playSong(item, in: sampleSongs)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }
    
    // Here we create a function to get Size of Top Safe Area
    private func getSafeAreaTop() -> CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .safeAreaInsets.top ?? 0
        
        return keyWindow
    }
}

// MARK: - Story Components

private struct StoryCircleView: View {
    let story: MusicStory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    if story.isViewed {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 70, height: 70)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pink, Color.orange, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                    }
                    
                    Circle()
                        .fill(Color.black)
                        .frame(width: 66, height: 66)
                    
                    if let profileImageURL = story.profileImageURL, !profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: profileImageURL)) { img in
                            img.resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .frame(width: 66, height: 66)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                
                Text(story.userName)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StoryCreationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storyManager: StoryManager
    @ObservedObject var songManager: SongManager
    @State private var selectedSong: SongsModel?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Create Music Story")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.top)
                    
                    Text("Select a song to share")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(sampleSongs) { song in
                            Button {
                                selectedSong = song
                                storyManager.createStory(with: song)
                                dismiss()
                            } label: {
                                VStack(spacing: 12) {
                                    AsyncImage(url: URL(string: song.cover)) { img in
                                        img.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    
                                    VStack(spacing: 4) {
                                        Text(song.title)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        
                                        Text(song.artist)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
