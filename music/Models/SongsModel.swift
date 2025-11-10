//
//  SongsModel.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI

// Now we create Songs Model List
struct SongsModel: Identifiable, Codable, Equatable {
    var id: String
    var artist: String
    var audio_url: String
    var cover: String
    var title: String
    var isFavourite: Bool = false
    var isDisliked: Bool = false
    
    init(id: String = UUID().uuidString, artist: String, audio_url: String, cover: String, title: String, isFavourite: Bool = false, isDisliked: Bool = false) {
        self.id = id
        self.artist = artist
        self.audio_url = audio_url
        self.cover = cover
        self.title = title
        self.isFavourite = isFavourite
        self.isDisliked = isDisliked
    }
}

// Demo List of Songs (fallback)
var sampleSongs: [SongsModel] = [
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1veW1fEVD-5wqd-_G8EC7ACVVC1D8jrV3", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Лето без тебя"),
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1Mg9bfPmczARpO_BNReFb0lS--ygYQWKz", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "Вечное лето")
]
