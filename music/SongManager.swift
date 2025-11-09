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
    
    @Published private(set) var song: SongsModel = SongsModel(artist: "", audio_url: "", cover: "", title: "")
    @Published private(set) var playlist: [SongsModel] = []
    @Published private(set) var currentIndex: Int?
    @Published private(set) var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published private(set) var isShuffling: Bool = false
    @Published private(set) var repeatMode: RepeatMode = .none
    
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
        if var providedPlaylist = playlist {
            if !providedPlaylist.contains(where: { $0.id == song.id }) {
                providedPlaylist.append(song)
            }
            
            guard let index = providedPlaylist.firstIndex(where: { $0.id == song.id }) else {
                return
            }
            playSong(at: index, playlist: providedPlaylist)
        } else if let currentIndex = self.playlist.firstIndex(where: { $0.id == song.id }) {
            playSong(at: currentIndex)
        } else if !originalPlaylist.isEmpty, let index = originalPlaylist.firstIndex(where: { $0.id == song.id }) {
            playSong(at: index, playlist: originalPlaylist)
        } else {
            playSong(at: 0, playlist: [song])
        }
    }
    
    func playSong(at index: Int, playlist newPlaylist: [SongsModel]? = nil) {
        if let newPlaylist {
            guard newPlaylist.indices.contains(index) else { return }
            let song = newPlaylist[index]
            originalPlaylist = newPlaylist
            
            if isShuffling {
                let shuffled = shuffledPlaylist(from: newPlaylist, keeping: song)
                playlist = shuffled
                currentIndex = shuffled.firstIndex(where: { $0.id == song.id }) ?? 0
            } else {
                playlist = newPlaylist
                currentIndex = index
            }
        } else {
            guard playlist.indices.contains(index) else { return }
            currentIndex = index
        }
        
        guard let currentIndex,
              playlist.indices.contains(currentIndex) else { return }
        
        let song = playlist[currentIndex]
        self.song = song
        currentTime = 0
        duration = 0
        
        preparePlayer(with: song.audio_url)
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
    
    private func shuffledPlaylist(from playlist: [SongsModel], keeping currentSong: SongsModel) -> [SongsModel] {
        var remainingSongs = playlist.filter { $0.id != currentSong.id }
        remainingSongs.shuffle()
        return [currentSong] + remainingSongs
    }
    
    // MARK: - Public Toggles
    
    func toggleShuffle() {
        let shouldShuffle = !isShuffling
        guard !originalPlaylist.isEmpty else { return }
        guard currentIndex != nil else { return }
        
        isShuffling = shouldShuffle
        
        if isShuffling {
            let shuffled = shuffledPlaylist(from: originalPlaylist, keeping: song)
            playlist = shuffled
            currentIndex = shuffled.firstIndex(where: { $0.id == song.id }) ?? 0
        } else {
            playlist = originalPlaylist
            currentIndex = playlist.firstIndex(where: { $0.id == song.id }) ?? 0
        }
    }
    
    func cycleRepeatMode() {
        repeatMode.cycle()
    }
}
