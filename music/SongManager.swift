//
//  SongManager.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI
import AVFoundation

class SongManager: ObservableObject {
    @Published private(set) var song: SongsModel = SongsModel(artist: "", audio_url: "", cover: "", title: "")
    
    private var player: AVPlayer?
    
    func playSong(song: SongsModel) {
        self.song = song
        if let url = URL(string: song.audio_url), !song.audio_url.isEmpty {
            player = AVPlayer(url: url)
            player?.play()
        } else {
            player = nil
        }
    }
    
    func pause() {
        player?.pause()
    }
}
