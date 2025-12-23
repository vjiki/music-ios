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
        
        currentSong = song
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
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                                    SampleCard(
                                        song: song,
                                        index: index,
                                        currentIndex: $currentIndex,
                                        totalSongs: songs.count,
                                        currentPlayingSong: samplesPlayer.currentSong,
                                        onVisible: { idx in
                                            if idx != lastPlayedIndex {
                                                currentIndex = idx
                                                playSong(at: idx)
                                                lastPlayedIndex = idx
                                            }
                                        }
                                    )
                                    .id(index)
                                    .environmentObject(songManager)
                                    .environmentObject(samplesPlayer)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                }
                            }
                        }
                        .scrollTargetBehavior(.paging)
                        .onAppear {
                            if lastPlayedIndex == -1 {
                                playSong(at: 0)
                                lastPlayedIndex = 0
                            }
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
        let song = songs[index]
        
        guard let url = URL(string: song.audio_url), !song.audio_url.isEmpty else { return }
        
        // Load and play song using separate player
        samplesPlayer.load(url: url, song: song)
        samplesPlayer.play()
        
        // Wait for duration to be available, then seek to middle
        Task {
            // Wait a bit for the audio to load
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Try to get duration and seek to middle
            var attempts = 0
            while samplesPlayer.duration == 0 && attempts < 15 {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                attempts += 1
            }
            
            if samplesPlayer.duration > 0 {
                let middleTime = samplesPlayer.duration / 2
                await MainActor.run {
                    samplesPlayer.seek(to: middleTime)
                }
            }
        }
    }
}

struct SampleCard: View {
    let song: SongsModel
    let index: Int
    @Binding var currentIndex: Int
    let totalSongs: Int
    let currentPlayingSong: SongsModel?
    let onVisible: (Int) -> Void
    
    @EnvironmentObject var songManager: SongManager
    @EnvironmentObject var samplesPlayer: SamplesAudioPlayer
    @State private var isLiked: Bool = false
    @State private var isDisliked: Bool = false
    
    // Use current playing song if available, otherwise get latest from library
    private var displaySong: SongsModel {
        // First check if there's a current playing song that matches
        if let currentPlaying = currentPlayingSong, currentPlaying.id == song.id {
            return currentPlaying
        }
        // Otherwise, get the latest version from library, or fallback to song prop
        if let librarySong = songManager.librarySongs.first(where: { $0.id == song.id }) {
            return librarySong
        }
        return song
    }
    
    // Check if this is the currently playing song
    private var isCurrentlyPlaying: Bool {
        currentPlayingSong?.id == song.id
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full screen cover image - use displaySong to show correct cover
                CachedAsyncImage(url: URL(string: displaySong.cover)) { image in
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
                        
                        // Like button
                        VStack(spacing: 8) {
                            Button {
                                Task {
                                    let userId = songManager.getCurrentUserId()
                                    let preferenceManager = PreferenceManager()
                                    let updatedSong = await preferenceManager.toggleLike(displaySong, userId: userId)
                                    // Update in library
                                    await MainActor.run {
                                        songManager.updateSongInLibrary(updatedSong)
                                        isLiked = updatedSong.isLiked
                                    }
                                }
                            } label: {
                                Image(systemName: displaySong.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: songManager.iconSize(for: displaySong.likesCount, baseSize: 28), weight: .medium))
                                    .foregroundStyle(displaySong.isLiked ? .pink : .white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            Text("\(displaySong.likesCount)")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        
                        // Dislike button
                        VStack(spacing: 8) {
                            Button {
                                Task {
                                    let userId = songManager.getCurrentUserId()
                                    let preferenceManager = PreferenceManager()
                                    let updatedSong = await preferenceManager.toggleDislike(displaySong, userId: userId)
                                    // Update in library
                                    await MainActor.run {
                                        songManager.updateSongInLibrary(updatedSong)
                                        isDisliked = updatedSong.isDisliked
                                    }
                                }
                            } label: {
                                Image(systemName: displaySong.isDisliked ? "heart.slash.fill" : "heart.slash")
                                    .font(.system(size: songManager.iconSize(for: displaySong.dislikesCount, baseSize: 28), weight: .medium))
                                    .foregroundStyle(displaySong.isDisliked ? .red : .white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            
                            Text("\(displaySong.dislikesCount)")
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
                
                // Bottom song info - use displaySong
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Album art thumbnail
                        CachedAsyncImage(url: URL(string: displaySong.cover)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Song info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displaySong.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            
                            Text(displaySong.artist)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // More options button
                        Button {
                            // More options
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .onAppear {
                // Check if this card is in the center of the screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onVisible(index)
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
        .onChange(of: samplesPlayer.currentSong?.id) { oldValue, newValue in
            // Update when the playing song changes
            if newValue == song.id {
                if let librarySong = songManager.librarySongs.first(where: { $0.id == song.id }) {
                    isLiked = librarySong.isLiked
                    isDisliked = librarySong.isDisliked
                }
            }
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
