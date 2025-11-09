//
//  SongsModel.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI

// Now we create Songs Model List
struct SongsModel: Identifiable {
    var id = UUID().uuidString
    var artist: String
    var audio_url: String
    var cover: String
    var title: String
    var isFavourite: Bool = false
    var isDisliked: Bool = false
}

// Demo List of Songs
var sampleSongs: [SongsModel] = [
    .init(artist: "Diljit Dosanjh", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", cover: "https://picsum.photos/200?random=1", title: "GOAT"),
    .init(artist: "Arijit Singh", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3", cover: "https://picsum.photos/200?random=2", title: "Hai Kude"),
    .init(artist: "Armaan Malik", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3", cover: "https://picsum.photos/200?random=3", title: "Making Memories"),
    .init(artist: "Jasleen Royal", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3", cover: "https://picsum.photos/200?random=4", title: "Heeriye"),
    .init(artist: "Jordan Sandhu", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3", cover: "https://picsum.photos/200?random=5", title: "Hateraan"),
    .init(artist: "B Praak", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3", cover: "https://picsum.photos/200?random=6", title: "Duppatta"),
    .init(artist: "Arijit Singh", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3", cover: "https://picsum.photos/200?random=7", title: "Just Friend"),
    .init(artist: "Darshan Raval", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3", cover: "https://picsum.photos/200?random=8", title: "Tera Zikr"),
    .init(artist: "Karan Randhawa", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3", cover: "https://picsum.photos/200?random=9", title: "Pulkaari"),
    .init(artist: "Parmish Verma", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3", cover: "https://picsum.photos/200?random=10", title: "Teri Aakh"),
    .init(artist: "Neha Kakkar", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3", cover: "https://picsum.photos/200?random=11", title: "Distance Love"),
    .init(artist: "Shubh", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3", cover: "https://picsum.photos/200?random=12", title: "One Love")
]
