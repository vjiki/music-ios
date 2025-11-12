//
//  SongManager.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI
import Foundation

// MARK: - PlaylistKind Enum
enum PlaylistKind: String, CaseIterable, Hashable {
    case liked
    case disliked
}

// MARK: - SongManager (Orchestrator - Dependency Inversion Principle)
class SongManager: ObservableObject {
    // MARK: - Dependencies (Dependency Inversion)
    private var audioPlayer: AudioPlayerServiceProtocol
    private let playlistManager: PlaylistManagerProtocol
    private let preferenceManager: PreferenceManagerProtocol
    private let nowPlayingService: NowPlayingServiceProtocol
    private let songsService: SongsServiceProtocol
    private var authService: AuthService?
    
    // MARK: - Published Properties
    @Published private(set) var song: SongsModel = SongsModel(artist: "", audio_url: "", cover: "", title: "")
    @Published private(set) var playlist: [SongsModel] = []
    @Published private(set) var currentIndex: Int?
    @Published private(set) var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published private(set) var isShuffling: Bool = false
    @Published private(set) var repeatMode: RepeatMode = .none
    @Published private(set) var librarySongs: [SongsModel] = []
    
    // MARK: - Computed Properties
    var likedSongIDs: Set<String> { preferenceManager.likedSongIDs }
    var dislikedSongIDs: Set<String> { preferenceManager.dislikedSongIDs }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        secondsToTimeString(currentTime)
    }
    
    var formattedDuration: String {
        secondsToTimeString(duration)
    }
    
    var repeatIconName: String {
        repeatMode.iconName
    }
    
    var likedSongs: [SongsModel] {
        preferenceManager.getLikedSongs(from: librarySongs)
    }
    
    var dislikedSongs: [SongsModel] {
        preferenceManager.getDislikedSongs(from: librarySongs)
    }
    
    var isCurrentSongLiked: Bool {
        preferenceManager.isLiked(song.id)
    }
    
    var isCurrentSongDisliked: Bool {
        preferenceManager.isDisliked(song.id)
    }
    
    var likeIconName: String {
        isCurrentSongLiked ? "heart.fill" : "heart"
    }
    
    var dislikeIconName: String {
        isCurrentSongDisliked ? "heart.slash.fill" : "heart.slash"
    }
    
    // MARK: - Initialization (Dependency Injection)
    init(
        audioPlayer: AudioPlayerServiceProtocol = AudioPlayerService(),
        playlistManager: PlaylistManagerProtocol = PlaylistManager(),
        preferenceManager: PreferenceManagerProtocol = PreferenceManager(),
        nowPlayingService: NowPlayingServiceProtocol = NowPlayingService(),
        songsService: SongsServiceProtocol = SongsService(),
        authService: AuthService? = nil
    ) {
        self.audioPlayer = audioPlayer
        self.playlistManager = playlistManager
        self.preferenceManager = preferenceManager
        self.nowPlayingService = nowPlayingService
        self.songsService = songsService
        self.authService = authService
        
        // Initialize with songs from service (fallback to sampleSongs)
        self.librarySongs = songsService.songs
        
        setupAudioPlayerCallbacks()
        setupNowPlayingService()
        
        // Fetch songs from API
        Task {
            await songsService.fetchSongs()
            await MainActor.run {
                self.librarySongs = songsService.songs
            }
        }
    }
    
    // MARK: - Public Methods
    
    func playSong(_ song: SongsModel, in playlist: [SongsModel]? = nil) {
        var basePlaylist = playlist ?? playlistManager.currentPlaylist
        if basePlaylist.isEmpty {
            basePlaylist = [song]
        } else if !basePlaylist.contains(where: { $0.id == song.id }) {
            basePlaylist.append(song)
        }
        
        playlistManager.configurePlaylist(basePlaylist, selecting: song)
        startPlaybackAtCurrentIndex()
    }
    
    func playSong(at index: Int, playlist newPlaylist: [SongsModel]? = nil) {
        if let newPlaylist {
            guard newPlaylist.indices.contains(index) else { return }
            let selectedSong = newPlaylist[index]
            playlistManager.configurePlaylist(newPlaylist, selecting: selectedSong)
        } else {
            playlistManager.setCurrentIndex(index)
        }
        
        startPlaybackAtCurrentIndex()
    }
    
    func play() {
        // If player is already playing, just call play
        if audioPlayer.isPlaying {
            audioPlayer.play()
            return
        }
        
        // If no song loaded, try to resume last song
        if currentTime == 0 && duration == 0 && song.audio_url.isEmpty {
            resumeLastSongIfPossible()
        } else {
            audioPlayer.play()
        }
    }
    
    func pause() {
        audioPlayer.pause()
    }
    
    func togglePlayPause() {
        isPlaying ? pause() : play()
    }
    
    func playNext(autoAdvance: Bool = false) {
        guard let currentSong = playlistManager.getCurrentSong() else { return }
        
        if autoAdvance, repeatMode == .one {
            audioPlayer.seek(to: 0)
            play()
            return
        }
        
        guard let nextIndex = playlistManager.getNextIndex() else {
            if autoAdvance {
                switch repeatMode {
                case .none:
                    pause()
                case .all:
                    if let firstIndex = playlistManager.currentPlaylist.indices.first {
                        playSong(at: firstIndex)
                    }
                case .one:
                    audioPlayer.seek(to: 0)
                    play()
                }
            }
            return
        }
        
        playSong(at: nextIndex)
    }
    
    func playPrevious() {
        guard let previousIndex = playlistManager.getPreviousIndex() else { return }
        playSong(at: previousIndex)
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer.seek(to: time)
    }
    
    func toggleShuffle() {
        playlistManager.toggleShuffle()
        isShuffling = playlistManager.isShuffling
        playlist = playlistManager.currentPlaylist
    }
    
    func cycleRepeatMode() {
        playlistManager.cycleRepeatMode()
        repeatMode = playlistManager.repeatMode
    }
    
    func toggleLike() {
        guard !song.title.isEmpty else { return }
        let userId = getCurrentUserId()
        Task {
            await preferenceManager.toggleLike(song.id, userId: userId)
            await MainActor.run {
                updateSongWithPreferences()
            }
        }
    }
    
    func toggleDislike() {
        guard !song.title.isEmpty else { return }
        let userId = getCurrentUserId()
        Task {
            await preferenceManager.toggleDislike(song.id, userId: userId)
            await MainActor.run {
                updateSongWithPreferences()
            }
        }
    }
    
    private func getCurrentUserId() -> String? {
        return authService?.currentUser?.id
    }
    
    func setAuthService(_ authService: AuthService) {
        self.authService = authService
    }
    
    func songs(for kind: PlaylistKind) -> [SongsModel] {
        switch kind {
        case .liked:
            return likedSongs
        case .disliked:
            return dislikedSongs
        }
    }
    
    func playPlaylist(_ songs: [SongsModel]) {
        guard !songs.isEmpty else { return }
        playSong(songs[0], in: songs)
    }
    
    func playPlaylist(_ kind: PlaylistKind) {
        playPlaylist(songs(for: kind))
    }
    
    func refreshSongs() async {
        await songsService.fetchSongs()
        await MainActor.run {
            self.librarySongs = songsService.songs
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioPlayerCallbacks() {
        audioPlayer.onTimeUpdate = { [weak self] time in
            self?.currentTime = time
            self?.updateNowPlayingInfo()
        }
        
        audioPlayer.onDurationUpdate = { [weak self] duration in
            self?.duration = duration
            self?.updateNowPlayingInfo()
        }
        
        audioPlayer.onPlaybackFinished = { [weak self] in
            self?.playNext(autoAdvance: true)
        }
        
        audioPlayer.onPlaybackStateChanged = { [weak self] isPlaying in
            self?.isPlaying = isPlaying
            self?.updateNowPlayingInfo()
        }
    }
    
    private func setupNowPlayingService() {
        nowPlayingService.setupRemoteCommandCenter(
            onPlay: { [weak self] in self?.play() },
            onPause: { [weak self] in self?.pause() },
            onToggle: { [weak self] in self?.togglePlayPause() },
            onNext: { [weak self] in self?.playNext() },
            onPrevious: { [weak self] in self?.playPrevious() },
            onSeek: { [weak self] time in self?.seek(to: time) },
            onLike: { [weak self] in self?.toggleLike() },
            onDislike: { [weak self] in self?.toggleDislike() }
        )
    }
    
    private func startPlaybackAtCurrentIndex() {
        guard let currentSong = playlistManager.getCurrentSong() else { return }
        
        updateSongWithPreferences(currentSong)
        syncLibrary(with: currentSong)
        
        song = currentSong
        currentIndex = playlistManager.currentIndex
        playlist = playlistManager.currentPlaylist
        isShuffling = playlistManager.isShuffling
        repeatMode = playlistManager.repeatMode
        
        currentTime = 0
        duration = 0
        
        // Check song like status from API when song starts playing
        let userId = getCurrentUserId()
        Task {
            await preferenceManager.checkSongLikeStatus(currentSong.id, userId: userId)
            await MainActor.run {
                updateSongWithPreferences(currentSong)
            }
        }
        
        guard let url = URL(string: currentSong.audio_url), !currentSong.audio_url.isEmpty else {
            return
        }
        
        audioPlayer.load(url: url)
        audioPlayer.play()
        updateNowPlayingInfo()
    }
    
    private func resumeLastSongIfPossible() {
        if let currentIndex = playlistManager.currentIndex {
            playSong(at: currentIndex)
        } else if !playlistManager.currentPlaylist.isEmpty {
            playSong(at: 0)
        } else if !song.audio_url.isEmpty {
            playSong(song)
        }
    }
    
    private func updateSongWithPreferences(_ song: SongsModel? = nil) {
        // Preferences are now managed through PreferenceManager
        // No need to update song properties as they are checked dynamically
        // This method is kept for potential future use
    }
    
    private func syncLibrary(with song: SongsModel) {
        if !librarySongs.contains(where: { $0.id == song.id }) {
            librarySongs.append(song)
        }
    }
    
    private func updateNowPlayingInfo() {
        nowPlayingService.update(
            song: song,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
        )
    }
    
    private func secondsToTimeString(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "0:00" }
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
