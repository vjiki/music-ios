//
//  SongManager.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI
import AVFoundation

class SongManager: ObservableObject {
    enum RepeatMode: Int, CaseIterable {
        case none
        case all
        case one
        
        mutating func cycle() {
            switch self {
            case .none:
                self = .all
            case .all:
                self = .one
            case .one:
                self = .none
            }
        }
        
        var iconName: String {
            switch self {
            case .none, .all:
                return "repeat"
            case .one:
                return "repeat.1"
            }
        }
    }
    
    enum PlaylistKind: String, CaseIterable, Hashable {
        case liked
        case disliked
    }
    
    @Published private(set) var song: SongsModel = SongsModel(artist: "", audio_url: "", cover: "", title: "")
    @Published private(set) var playlist: [SongsModel] = []
    @Published private(set) var currentIndex: Int?
    @Published private(set) var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published private(set) var isShuffling: Bool = false
    @Published private(set) var repeatMode: RepeatMode = .none
    @Published private(set) var librarySongs: [SongsModel] = sampleSongs
    @Published private(set) var likedSongIDs: Set<String> = []
    @Published private(set) var dislikedSongIDs: Set<String> = []
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var playbackFinishedObserver: Any?
    private var originalPlaylist: [SongsModel] = []
    
    init() {
        configureAudioSession()
    }
    
    deinit {
        cleanupPlayer()
    }
    
    func playSong(_ song: SongsModel, in playlist: [SongsModel]? = nil) {
        var basePlaylist = playlist ?? originalPlaylist
        if basePlaylist.isEmpty {
            basePlaylist = [song]
        } else if !basePlaylist.contains(where: { $0.id == song.id }) {
            basePlaylist.append(song)
        }
        
        configurePlaylist(with: basePlaylist, selecting: song)
        startPlaybackAtCurrentIndex()
    }
    
    func playSong(at index: Int, playlist newPlaylist: [SongsModel]? = nil) {
        if let newPlaylist {
            guard newPlaylist.indices.contains(index) else { return }
            let selectedSong = newPlaylist[index]
            configurePlaylist(with: newPlaylist, selecting: selectedSong)
        } else {
            guard playlist.indices.contains(index) else { return }
            currentIndex = index
        }
        
        startPlaybackAtCurrentIndex()
    }
    
    func play() {
        guard let player else {
            resumeLastSongIfPossible()
            return
        }
        
        player.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        isPlaying ? pause() : play()
    }
    
    func playNext(autoAdvance: Bool = false) {
        guard let currentIndex, !playlist.isEmpty else {
            return
        }
        
        if autoAdvance, repeatMode == .one {
            seek(to: 0)
            play()
            return
        }
        
        var nextIndex = currentIndex + 1
        if nextIndex >= playlist.count {
            if autoAdvance {
                switch repeatMode {
                case .none:
                    pause()
                    return
                case .all:
                    nextIndex = 0
                case .one:
                    // handled above
                    return
                }
            } else {
                switch repeatMode {
                case .none, .all:
                    nextIndex = 0
                case .one:
                    nextIndex = (playlist.count > 1) ? 0 : currentIndex
                }
            }
        }
        
        playSong(at: nextIndex)
    }
    
    func playPrevious() {
        guard let currentIndex, !playlist.isEmpty else {
            return
        }
        
        let previousIndex = currentIndex - 1
        if playlist.indices.contains(previousIndex) {
            playSong(at: previousIndex)
        } else if let lastIndex = playlist.indices.last {
            playSong(at: lastIndex)
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player else { return }
        let clampedTime = min(max(time, 0), duration)
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clampedTime
    }
    
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
        librarySongs
            .filter { likedSongIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    
    var dislikedSongs: [SongsModel] {
        librarySongs
            .filter { dislikedSongIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
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
    
    var isCurrentSongLiked: Bool {
        likedSongIDs.contains(song.id)
    }
    
    var isCurrentSongDisliked: Bool {
        dislikedSongIDs.contains(song.id)
    }
    
    var likeIconName: String {
        isCurrentSongLiked ? "heart.fill" : "heart"
    }
    
    var dislikeIconName: String {
        isCurrentSongDisliked ? "heart.slash.fill" : "heart.slash"
    }
    
    // MARK: - Private Helpers
    
    private func preparePlayer(with urlString: String) {
        cleanupPlayer()
        
        guard let url = URL(string: urlString), !urlString.isEmpty else {
            player = nil
            isPlaying = false
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        addPlaybackObservers(for: playerItem)
        addPeriodicTimeObserver()
        player?.play()
        isPlaying = true
    }
    
    private func resumeLastSongIfPossible() {
        if let currentIndex {
            playSong(at: currentIndex)
        } else if !playlist.isEmpty {
            playSong(at: 0)
        } else if !song.audio_url.isEmpty {
            playSong(song)
        }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    private func cleanupPlayer() {
        if let timeObserverToken, let player {
            player.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
        
        if let playbackFinishedObserver {
            NotificationCenter.default.removeObserver(playbackFinishedObserver)
        }
        playbackFinishedObserver = nil
        
        player?.pause()
        player = nil
    }
    
    private func addPeriodicTimeObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            
            let currentSeconds = time.seconds
            if currentSeconds.isFinite {
                self.currentTime = currentSeconds
            }
            
            if let durationSeconds = player.currentItem?.duration.seconds, durationSeconds.isFinite {
                self.duration = durationSeconds
            }
        }
    }
    
    private func addPlaybackObservers(for item: AVPlayerItem) {
        playbackFinishedObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.playNext(autoAdvance: true)
        }
    }
    
    private func secondsToTimeString(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "0:00" }
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func configurePlaylist(with basePlaylist: [SongsModel], selecting selectedSong: SongsModel) {
        let preparedPlaylist = basePlaylist.map { song -> SongsModel in
            var updated = song
            updated.isFavourite = likedSongIDs.contains(song.id)
            updated.isDisliked = dislikedSongIDs.contains(song.id)
            return updated
        }
        
        guard !preparedPlaylist.isEmpty else {
            playlist = []
            originalPlaylist = []
            currentIndex = nil
            return
        }
        
        ensureSongsInLibrary(preparedPlaylist)
        originalPlaylist = preparedPlaylist
        
        let selectedID = selectedSong.id
        let resolvedSong = preparedPlaylist.first(where: { $0.id == selectedID }) ?? preparedPlaylist[0]
        
        if isShuffling {
            playlist = shuffledPlaylist(from: preparedPlaylist, keeping: resolvedSong)
        } else {
            playlist = preparedPlaylist
        }
        
        currentIndex = playlist.firstIndex(where: { $0.id == resolvedSong.id }) ?? 0
    }
    
    private func startPlaybackAtCurrentIndex() {
        guard let currentIndex,
              playlist.indices.contains(currentIndex) else { return }
        
        var currentSong = playlist[currentIndex]
        currentSong.isFavourite = likedSongIDs.contains(currentSong.id)
        currentSong.isDisliked = dislikedSongIDs.contains(currentSong.id)
        updateStoredSong(currentSong)
        syncLibrary(with: currentSong)
        
        song = currentSong
        currentTime = 0
        duration = 0
        
        preparePlayer(with: currentSong.audio_url)
    }
    
    private func refreshCurrentSong() {
        guard let currentIndex,
              playlist.indices.contains(currentIndex) else { return }
        
        var currentSong = playlist[currentIndex]
        currentSong.isFavourite = likedSongIDs.contains(currentSong.id)
        currentSong.isDisliked = dislikedSongIDs.contains(currentSong.id)
        updateStoredSong(currentSong)
        syncLibrary(with: currentSong)
        
        song = currentSong
    }
    
    private func updateStoredSong(_ updatedSong: SongsModel) {
        if let playlistIndex = playlist.firstIndex(where: { $0.id == updatedSong.id }) {
            playlist[playlistIndex] = updatedSong
        }
        if let originalIndex = originalPlaylist.firstIndex(where: { $0.id == updatedSong.id }) {
            originalPlaylist[originalIndex] = updatedSong
        }
        syncLibrary(with: updatedSong)
    }
    
    private func ensureSongsInLibrary(_ songs: [SongsModel]) {
        songs.forEach { syncLibrary(with: $0) }
    }
    
    private func syncLibrary(with song: SongsModel) {
        var updatedSong = song
        updatedSong.isFavourite = likedSongIDs.contains(song.id)
        updatedSong.isDisliked = dislikedSongIDs.contains(song.id)
        
        if let index = librarySongs.firstIndex(where: { $0.id == updatedSong.id }) {
            librarySongs[index] = updatedSong
        } else {
            librarySongs.append(updatedSong)
        }
    }
    
    private func shuffledPlaylist(from playlist: [SongsModel], keeping currentSong: SongsModel) -> [SongsModel] {
        var remainingSongs = playlist.filter { $0.id != currentSong.id }
        remainingSongs.shuffle()
        return [currentSong] + remainingSongs
    }
    
    // MARK: - Public Toggles
    
    func toggleShuffle() {
        guard hasActiveSong, !originalPlaylist.isEmpty else { return }
        
        isShuffling.toggle()
        
        if isShuffling {
            let baseSong = originalPlaylist.first(where: { $0.id == song.id }) ?? song
            playlist = shuffledPlaylist(from: originalPlaylist, keeping: baseSong)
        } else {
            playlist = originalPlaylist
        }
        
        currentIndex = playlist.firstIndex(where: { $0.id == song.id }) ?? currentIndex
        refreshCurrentSong()
    }
    
    func cycleRepeatMode() {
        repeatMode.cycle()
    }
    
    func toggleLike() {
        guard hasActiveSong else { return }
        
        if likedSongIDs.contains(song.id) {
            likedSongIDs.remove(song.id)
        } else {
            likedSongIDs.insert(song.id)
            dislikedSongIDs.remove(song.id)
        }
        
        var updatedSong = song
        updatedSong.isFavourite = likedSongIDs.contains(song.id)
        updatedSong.isDisliked = dislikedSongIDs.contains(song.id)
        updateStoredSong(updatedSong)
        song = updatedSong
        refreshCurrentSong()
    }
    
    func toggleDislike() {
        guard hasActiveSong else { return }
        
        if dislikedSongIDs.contains(song.id) {
            dislikedSongIDs.remove(song.id)
        } else {
            dislikedSongIDs.insert(song.id)
            likedSongIDs.remove(song.id)
        }
        
        var updatedSong = song
        updatedSong.isFavourite = likedSongIDs.contains(song.id)
        updatedSong.isDisliked = dislikedSongIDs.contains(song.id)
        updateStoredSong(updatedSong)
        song = updatedSong
        refreshCurrentSong()
    }
    
    private var hasActiveSong: Bool {
        if let currentIndex {
            return playlist.indices.contains(currentIndex)
        }
        return !song.audio_url.isEmpty
    }
}
