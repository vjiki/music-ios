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
}

// Demo List of Songs
var sampleSongs: [SongsModel] = [
    .init(artist: "Diljit Dosanjh", audio_url: "https://aac.saavncdn.com/249/7a02f7e2UAAAMAAIADiQgAACDAAABe-AI-CYACDAMkgyMhyyh3MuB-rxAn0nCLAtXvQ4NqsIpPvwh-QGCifw", cover: "https://c.saavncdn.com/249/7a02f7e2UAAAMAAIADiQgAACDAAABe-AI-CYACDAMkgyMhyyh3MuB-rxAn0nCLAtXvQ4NqsIpPvwh-QGCifw.jpg", title: "GOAT"),
    .init(artist: "Arijit Singh", audio_url: "https://aac.saavncdn.com/758/a5417aae2-d79a-45a1-9d8b-c70a4a4/cover/ab0f-d6b0-bf0.jpg", cover: "https://c.saavncdn.com/758/a5417aae2-d79a-45a1-9d8b-c70a4a4/cover/ab0f-d6b0-bf0.jpg", title: "Hai Kude"),
    .init(artist: "Armaan Malik", audio_url: "https://aac.saavncdn.com/583/4b593fdb6c/cover/9f0-8b6f-8800.jpg", cover: "https://c.saavncdn.com/583/4b593fdb6c/cover/9f0-8b6f-8800.jpg", title: "Making Memories"),
    .init(artist: "Jasleen Royal", audio_url: "", cover: "", title: "Heeriye"),
    .init(artist: "Jordan Sandhu", audio_url: "", cover: "https://ytimg.com/vi/8DAI0dWad0/maxresdefault.jpg", title: "Hateraan"),
    .init(artist: "B Praak", audio_url: "", cover: "https://i1.sndcdn.com/artworks-0Cdd5T7Q0ShK6p0.jpg", title: "Duppatta"),
    .init(artist: "Arijit Singh", audio_url: "", cover: "https://i1.sndcdn.com/artworks-0Cdd5T7Q0ShK6p0.jpg", title: "Just Friend"),
    .init(artist: "Darshan Raval", audio_url: "", cover: "https://i1.sndcdn.com/artworks-000705024950-585B59-t500x500.jpg", title: "Tera Zikr"),
    .init(artist: "Karan Randhawa", audio_url: "", cover: "https://i1.sndcdn.com/artworks-000705024950-585B59-t500x500.jpg", title: "Pulkaari"),
    .init(artist: "Parmish Verma", audio_url: "", cover: "https://i1.sndcdn.com/artworks-000705024950-585B59-t500x500.jpg", title: "Teri Aakh"),
    .init(artist: "Neha Kakkar", audio_url: "", cover: "https://m.media-amazon.com/images/I/71ZDLF1B9sL._UXNaN_FMjpg_QL85_.jpg", title: "Distance Love"),
    .init(artist: "Shubh", audio_url: "", cover: "https://m.media-amazon.com/images/I/61O87sE0cSL._UXNaN_FMjpg_QL85_.jpg", title: "One Love")
]
