//
//  SongManager.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI

class SongManager: ObservableObject {
    @Published private(set) var song: SongsModel = SongsModel(artist: "", audio_url: "", cover: "", title: "")
    
    func playSong(song: SongsModel) {
        self.song = song
    }
    
}
