//
//  AudioPlayerService.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import Foundation
import AVFoundation

// MARK: - Protocol (Interface Segregation)
protocol AudioPlayerServiceProtocol {
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }
    
    func play()
    func pause()
    func seek(to time: TimeInterval)
    func load(url: URL)
    func stop()
    
    var onTimeUpdate: ((TimeInterval) -> Void)? { get set }
    var onDurationUpdate: ((TimeInterval) -> Void)? { get set }
    var onPlaybackFinished: (() -> Void)? { get set }
    var onPlaybackStateChanged: ((Bool) -> Void)? { get set }
}

// MARK: - Implementation (Single Responsibility: Audio Playback)
class AudioPlayerService: AudioPlayerServiceProtocol {
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var playbackFinishedObserver: Any?
    
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    private(set) var isPlaying: Bool = false
    
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onDurationUpdate: ((TimeInterval) -> Void)?
    var onPlaybackFinished: (() -> Void)?
    var onPlaybackStateChanged: ((Bool) -> Void)?
    
    init() {
        configureAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    func play() {
        player?.play()
        isPlaying = true
        onPlaybackStateChanged?(true)
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        onPlaybackStateChanged?(false)
    }
    
    func seek(to time: TimeInterval) {
        guard let player else { return }
        let clampedTime = min(max(time, 0), duration)
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clampedTime
    }
    
    func load(url: URL) {
        cleanup()
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        addPlaybackObservers(for: playerItem)
        addPeriodicTimeObserver()
        
        currentTime = 0
        duration = 0
    }
    
    func stop() {
        cleanup()
        isPlaying = false
        onPlaybackStateChanged?(false)
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
    
    private func addPeriodicTimeObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            
            let currentSeconds = time.seconds
            if currentSeconds.isFinite {
                self.currentTime = currentSeconds
                self.onTimeUpdate?(currentSeconds)
            }
            
            if let durationSeconds = player.currentItem?.duration.seconds, durationSeconds.isFinite {
                if abs(self.duration - durationSeconds) > 0.1 {
                    self.duration = durationSeconds
                    self.onDurationUpdate?(durationSeconds)
                }
            }
        }
    }
    
    private func addPlaybackObservers(for item: AVPlayerItem) {
        playbackFinishedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.onPlaybackFinished?()
        }
    }
    
    private func cleanup() {
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
}

