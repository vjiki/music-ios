//
//  Home.swift
//  music
//
//  Created by Nikolai Golubkin on 15. 8. 2025..
//

import SwiftUI

struct Home: View {
    enum Tab: Hashable, CaseIterable {
        case home
        case search
        case playlists
        case profile
    }
    
    @State private var expandSheet = false
    @State private var storyImageURL: String? = nil
    @Namespace private var animation
    @StateObject var authService = AuthService()
    @StateObject var songManager = SongManager(authService: nil) // Will be set in onAppear
    @State private var currentTab: Tab = .home
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        TabView(selection: $currentTab) {
            HomeTabContent(expandSheet: $expandSheet, animation: animation, storyImageURL: $storyImageURL)
                .tag(Tab.home)
                .environmentObject(songManager)
                .environmentObject(authService)
            
            Search(expandSheet: $expandSheet, animation: animation)
                .tag(Tab.search)
                .environmentObject(songManager)
                .environmentObject(authService)
            
            PlaylistsView()
                .tag(Tab.playlists)
                .environmentObject(songManager)
                .environmentObject(authService)
            
            ProfileView()
                .tag(Tab.profile)
                .environmentObject(songManager)
                .environmentObject(authService)
        }
        .background(Color.black.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if !songManager.song.title.isEmpty {
                    MiniPlayer()
                        .padding(.horizontal, 18)
                        .padding(.bottom, 8)
                }
                
                CustomTabBar(currentTab: $currentTab)
            }
            .opacity(expandSheet ? 0 : 1)
            .allowsHitTesting(!expandSheet)
        }
        .overlay {
            if expandSheet {
                ZStack {
                    // Opaque black background to hide content behind
                    Color.black
                        .ignoresSafeArea()
                    
                    MusicView(expandSheet: $expandSheet, animation: animation, storyImageURL: storyImageURL)
                        .environmentObject(songManager)
                        .environmentObject(authService)
                }
            }
        }
        .onChange(of: authService.shouldNavigateToProfile) { _, shouldNavigate in
            if shouldNavigate {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentTab = .profile
                }
                // Reset the flag after navigation
                Task { @MainActor in
                    authService.shouldNavigateToProfile = false
                }
            }
        }
        .onChange(of: expandSheet) { _, isExpanded in
            // Reset story image URL when MusicView is closed
            if !isExpanded {
                storyImageURL = nil
            }
        }
        .onAppear {
            // Set AuthService in SongManager
            songManager.setAuthService(authService)
        }
    }
    
    @ViewBuilder
    private func MiniPlayer() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.24), radius: 10, x: 0, y: 6)
                .overlay {
                    MusicInfo(expandSheet: $expandSheet, animation: animation)
                        .environmentObject(songManager)
                        .padding(.horizontal, 10)
                }
        }
        .frame(height: 58)
        .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
    }
    
    private struct CustomTabBar: View {
        @Binding var currentTab: Tab
        
        private let items: [TabItem] = [
            TabItem(tab: .home, icon: "house", selectedIcon: "house.fill"),
            TabItem(tab: .search, icon: "magnifyingglass", selectedIcon: "magnifyingglass"),
            TabItem(tab: .playlists, icon: "play.square", selectedIcon: "play.square.fill"),
            TabItem(tab: .profile, icon: "person.crop.circle", selectedIcon: "person.crop.circle.fill")
        ]
        
        var body: some View {
            HStack {
                ForEach(items) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            currentTab = item.tab
                        }
                    } label: {
                        Image(systemName: iconName(for: item.tab))
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(currentTab == item.tab ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.95))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 0.5),
                alignment: .top
            )
        }
        
        private func iconName(for tab: Tab) -> String {
            guard let item = items.first(where: { $0.tab == tab }) else {
                return "circle"
            }
            return currentTab == tab ? item.selectedIcon : item.icon
        }
        
        private struct TabItem: Identifiable {
            let tab: Tab
            let icon: String
            let selectedIcon: String
            var id: Tab { tab }
        }
    }
}

// MARK: - Home Tab Content
private struct HomeTabContent: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    @Binding var storyImageURL: String?
    
    @EnvironmentObject var songManager: SongManager
    @EnvironmentObject var authService: AuthService
    @StateObject private var storyManager = StoryManager()
    @StateObject private var storiesService = StoriesService()
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
        .task {
            // Fetch stories from API when view appears
            await fetchStoriesFromAPI()
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            // Refetch stories when authentication state changes
            if isAuthenticated {
                Task {
                    await fetchStoriesFromAPI()
                }
            }
        }
        .sheet(isPresented: $showStoryCreation) {
            StoryCreationView(storyManager: storyManager, songManager: songManager)
        }
        .sheet(isPresented: $showMessages) {
            MessagesView()
                .environmentObject(authService)
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
                    if let first = songManager.librarySongs.first {
                        songManager.playSong(first, in: songManager.librarySongs)
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
                            // Only open if song has audio URL
                            guard !story.song.audio_url.isEmpty else {
                                // Mark as viewed even if can't play
                                storyManager.markStoryAsViewed(story.id)
                                return
                            }
                            
                            // Set the story image URL first
                            storyImageURL = story.storyImageURL ?? story.storyPreviewURL
                            
                            // Play the song from the story
                            songManager.playSong(story.song, in: [story.song])
                            
                            // Open MusicView with animation
                            withAnimation(.easeInOut(duration: 0.3)) {
                                expandSheet = true
                            }
                            
                            // Mark story as viewed
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
                if let first = songManager.librarySongs.first {
                    songManager.playSong(first, in: songManager.librarySongs)
                }
            }
            
            discoverCard(
                title: "Trends",
                subtitle: "What's hot now",
                icon: "flame.fill"
            ) {
                if let randomSong = songManager.librarySongs.randomElement() {
                    songManager.playSong(randomSong, in: songManager.librarySongs.shuffled())
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
                    ForEach(songManager.librarySongs, id: \.id) { item in
                        Button {
                            songManager.playSong(item, in: songManager.librarySongs)
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
                    if let first = songManager.librarySongs.first {
                        songManager.playSong(first, in: songManager.librarySongs)
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
                    ForEach(songManager.librarySongs, id: \.id) { item in
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
                            songManager.playSong(item, in: songManager.librarySongs)
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
    
    // Fetch stories from API
    private func fetchStoriesFromAPI() async {
        // Only fetch if user is authenticated
        guard authService.isAuthenticated,
              let currentUserId = authService.currentUser?.id else {
            // Use fallback stories if not authenticated
            if !songManager.librarySongs.isEmpty {
                storyManager.updateStories(from: songManager.librarySongs)
            }
            return
        }
        
        // Fetch followers for current user
        var followers: [FollowerResponse] = []
        do {
            followers = try await storiesService.fetchFollowers(for: currentUserId)
        } catch {
            print("Failed to fetch followers: \(error.localizedDescription)")
        }
        
        // Fetch stories from API
        await storyManager.fetchStoriesFromAPI(
            currentUserId: currentUserId,
            followers: followers,
            allSongs: songManager.librarySongs
        )
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
                        ForEach(songManager.librarySongs) { song in
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
    Home()
        .preferredColorScheme(.dark)
}
