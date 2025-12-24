//
//  SamplesView.swift
//  music
//
//  Created by Nikolai Golubkin on 11/12/25.
//

import SwiftUI
import AVFoundation

// Separate audio player for SamplesView
class SamplesAudioPlayer: NSObject, ObservableObject {
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var playbackFinishedObserver: Any?
    
    @Published var currentSong: SongsModel?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func seek(to time: TimeInterval) {
        guard let player else { return }
        let clampedTime = min(max(time, 0), duration)
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clampedTime
    }
    
    func load(url: URL, song: SongsModel) {
        cleanup()
        
        // Update current song FIRST on main thread to trigger UI updates immediately
        Task { @MainActor in
            self.currentSong = song
        }
        
        // Check cache first
        let cacheService = CacheService.shared
        let finalURL: URL
        
        if let cachedURL = cacheService.getCachedAudioURL(url: url) {
            finalURL = cachedURL
        } else {
            finalURL = url
            // Cache audio in background
            Task {
                await cacheAudio(url: url, song: song)
            }
        }
        
        let playerItem = AVPlayerItem(url: finalURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Remove old observer if exists
        currentPlayerItem?.removeObserver(self, forKeyPath: "duration")
        
        currentPlayerItem = playerItem
        addPlaybackObservers(for: playerItem)
        addPeriodicTimeObserver()
        
        currentTime = 0
        duration = 0
    }
    
    private func cacheAudio(url: URL, song: SongsModel) async {
        let cacheService = CacheService.shared
        if cacheService.hasCachedAudio(url: url) { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            cacheService.cacheAudio(url: url, data: data, title: song.title, artist: song.artist, coverURL: song.cover)
        } catch {
            print("Failed to cache audio: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        cleanup()
        isPlaying = false
        currentSong = nil
    }
    
    private var currentPlayerItem: AVPlayerItem?
    
    private func cleanup() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        
        if let observer = playbackFinishedObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackFinishedObserver = nil
        }
        
        // Remove KVO observer
        currentPlayerItem?.removeObserver(self, forKeyPath: "duration")
        currentPlayerItem = nil
        
        player?.pause()
        player = nil
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
        }
    }
    
    private func addPlaybackObservers(for item: AVPlayerItem) {
        // Observe duration
        let durationKeyPath = \AVPlayerItem.duration
        item.addObserver(self, forKeyPath: "duration", options: [.new], context: nil)
        
        // Observe playback finished
        playbackFinishedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let item = object as? AVPlayerItem, item.duration.seconds.isFinite {
            DispatchQueue.main.async { [weak self] in
                self?.duration = item.duration.seconds
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

struct SamplesView: View {
    @EnvironmentObject var songManager: SongManager
    @StateObject private var samplesPlayer = SamplesAudioPlayer()
    @State private var currentIndex: Int = 0
    @State private var lastPlayedIndex: Int = -1
    
    private var songs: [SongsModel] {
        songManager.librarySongs
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !songs.isEmpty {
                    ZStack {
                        TabView(selection: $currentIndex) {
                            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                                SampleCard(
                                    song: song,
                                    index: index,
                                    currentIndex: $currentIndex,
                                    totalSongs: songs.count,
                                    currentPlayingSongId: samplesPlayer.currentSong?.id
                                )
                                .tag(index)
                                .environmentObject(songManager)
                                .environmentObject(samplesPlayer)
                                .frame(width: geometry.size.height, height: geometry.size.width)
                                .rotationEffect(.degrees(90))
                                .scaleEffect(x: 1, y: -1)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .indexViewStyle(.page(backgroundDisplayMode: .never))
                        .rotationEffect(.degrees(90))
                        .scaleEffect(x: 1, y: -1)
                        .frame(width: geometry.size.height, height: geometry.size.width)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onChange(of: currentIndex) { oldValue, newValue in
                        if newValue != lastPlayedIndex {
                            playSong(at: newValue)
                            lastPlayedIndex = newValue
                        }
                    }
                    .onAppear {
                        if lastPlayedIndex == -1 {
                            playSong(at: 0)
                            lastPlayedIndex = 0
                        }
                    }
                } else {
                    VStack {
                        ProgressView()
                            .tint(.white)
                        Text("Loading samples...")
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 16)
                    }
                }
            }
        }
        .onDisappear {
            // Stop playback when leaving samples view
            samplesPlayer.stop()
        }
    }
    
    private func playSong(at index: Int) {
        guard index >= 0 && index < songs.count else { return }
        // Get the latest version from library to ensure correct cover and metadata
        let song = songs[index]
        let latestSong = songManager.librarySongs.first(where: { $0.id == song.id }) ?? song
        
        guard let url = URL(string: latestSong.audio_url), !latestSong.audio_url.isEmpty else { return }
        
        // Update current song immediately on main thread to update UI synchronously
        DispatchQueue.main.async {
            samplesPlayer.currentSong = latestSong
        }
        
        // Load and play song using separate player with latest song data
        // Play from the beginning (no seeking to middle)
        samplesPlayer.load(url: url, song: latestSong)
        samplesPlayer.play()
    }
}

struct SampleCard: View {
    let song: SongsModel
    let index: Int
    @Binding var currentIndex: Int
    let totalSongs: Int
    let currentPlayingSongId: String?
    
    @EnvironmentObject var songManager: SongManager
    @EnvironmentObject var samplesPlayer: SamplesAudioPlayer
    @State private var isLiked: Bool = false
    @State private var isDisliked: Bool = false
    
    // Get the song to display - prioritize currently playing song if this card matches it
    private var displaySong: SongsModel {
        // Always use the currently playing song if this card matches it
        if let currentPlaying = samplesPlayer.currentSong, currentPlaying.id == song.id {
            return currentPlaying
        }
        // Otherwise, get the latest version from library, or fallback to song prop
        if let librarySong = songManager.librarySongs.first(where: { $0.id == song.id }) {
            return librarySong
        }
        return song
    }
    
    // Check if this is the currently playing song - use both sources for reactivity
    private var isCurrentlyPlaying: Bool {
        let currentId = currentPlayingSongId ?? samplesPlayer.currentSong?.id
        return currentId == song.id
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full screen cover image - show cover for currently playing song if this card matches it
                // Note: geometry dimensions are swapped because we're in a rotated TabView
                let coverToShow = isCurrentlyPlaying ? (samplesPlayer.currentSong?.cover ?? song.cover) : song.cover
                
                CachedAsyncImage(url: URL(string: coverToShow)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea(.all)
                
                // Dark overlay for better text readability
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Right side interaction buttons (centered vertically)
                HStack {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Like button - use current playing song if this is it
                        let buttonSong = isCurrentlyPlaying ? (samplesPlayer.currentSong ?? song) : song
                        VStack(spacing: 8) {
                            Button {
                                Task {
                                    let userId = songManager.getCurrentUserId()
                                    let preferenceManager = PreferenceManager()
                                    let updatedSong = await preferenceManager.toggleLike(buttonSong, userId: userId)
                                    // Update in library
                                    await MainActor.run {
                                        songManager.updateSongInLibrary(updatedSong)
                                        // Update samplesPlayer currentSong if it's the same
                                        if samplesPlayer.currentSong?.id == updatedSong.id {
                                            samplesPlayer.currentSong = updatedSong
                                        }
                                        isLiked = updatedSong.isLiked
                                    }
                                }
                            } label: {
                                Image(systemName: buttonSong.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: songManager.iconSize(for: buttonSong.likesCount, baseSize: 28), weight: .medium))
                                    .foregroundStyle(buttonSong.isLiked ? .pink : .white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            Text("\(buttonSong.likesCount)")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        
                        // Dislike button - use current playing song if this is it
                        VStack(spacing: 8) {
                            Button {
                                Task {
                                    let userId = songManager.getCurrentUserId()
                                    let preferenceManager = PreferenceManager()
                                    let updatedSong = await preferenceManager.toggleDislike(buttonSong, userId: userId)
                                    // Update in library
                                    await MainActor.run {
                                        songManager.updateSongInLibrary(updatedSong)
                                        // Update samplesPlayer currentSong if it's the same
                                        if samplesPlayer.currentSong?.id == updatedSong.id {
                                            samplesPlayer.currentSong = updatedSong
                                        }
                                        isDisliked = updatedSong.isDisliked
                                    }
                                }
                            } label: {
                                Image(systemName: buttonSong.isDisliked ? "heart.slash.fill" : "heart.slash")
                                    .font(.system(size: songManager.iconSize(for: buttonSong.dislikesCount, baseSize: 28), weight: .medium))
                                    .foregroundStyle(buttonSong.isDisliked ? .red : .white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            Text("\(buttonSong.dislikesCount)")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        
                        // Comment button
                        VStack(spacing: 8) {
                            Button {
                                // Comment action
                            } label: {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            Text("0")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.trailing, 16)
                }
            }
        }
        .onAppear {
            // Update state from library song
            if let librarySong = songManager.librarySongs.first(where: { $0.id == song.id }) {
                isLiked = librarySong.isLiked
                isDisliked = librarySong.isDisliked
            } else {
                isLiked = song.isLiked
                isDisliked = song.isDisliked
            }
        }
        .onChange(of: samplesPlayer.currentSong) { oldValue, newValue in
            // Force view refresh when current song changes - this ensures cover updates
            // Update like/dislike state if this card matches
            if newValue?.id == song.id {
                if let librarySong = songManager.librarySongs.first(where: { $0.id == song.id }) {
                    isLiked = librarySong.isLiked
                    isDisliked = librarySong.isDisliked
                }
            }
        }
        .onChange(of: samplesPlayer.currentSong?.id) { oldValue, newValue in
            // Additional onChange to ensure view updates when song ID changes
        }
        .onChange(of: songManager.librarySongs) { oldValue, newValue in
            // Update when library songs change (e.g., after like/dislike)
            if let librarySong = newValue.first(where: { $0.id == song.id }) {
                isLiked = librarySong.isLiked
                isDisliked = librarySong.isDisliked
            }
        }
    }
}

#Preview {
    SamplesView()
        .environmentObject(SongManager())
        .preferredColorScheme(.dark)
}
