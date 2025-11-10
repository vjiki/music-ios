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
    .init(artist: "Shubh", audio_url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3", cover: "https://picsum.photos/200?random=12", title: "One Love"),
    // Scotch songs
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1Lyi-7lOLELU6sAjd3D9saShX6Hza56dK", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Шаг в темноту"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1kA19c1o1eK0ZFlCslmU6hmm-Tuot9hsA", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Реки слез"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1fyqbJobeUTZeaIP5b9ece5pUbVpAJG7O", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Цветы зла"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1eqERA3CsWVnzIHSeZKw2Y1tq14AOYizp", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Домино"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1qzlR0z8JCSQb8eTwYk7pODm8003DLj8p", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Звезды"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=19x6DQTF4lJ-T-Lq5s5poyVFLhN3dCFH-", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Падение"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1eQQRSq7hlk7YoMALUVfy6S9ivRhm5fA3", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Твой Мир"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1veW1fEVD-5wqd-_G8EC7ACVVC1D8jrV3", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Лето без тебя"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1hvzblDwo3pbHzTt7SKGSo4iBpBxBi9sq", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Горизонты"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1tfS0PN9_2jaP7xHs_eDu5hSF8zyOhu1z", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Холод стен"),
    .init(artist: "Scotch", audio_url: "https://drive.google.com/uc?export=download&id=1zz2uJavwLDsgzGNWq-gE8nnrZ8_F3J2i", cover: "https://drive.google.com/uc?export=download&id=1pYVYMKPWFoBqof8e_bLCpfME8rwekpLd", title: "Не может длиться вечно"),
    // 7раса songs
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1etxvzJXhdinj121-3fjNbq6bnh9PWIuL", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "1й круг"),
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1vLi0-msdE7ywANn6TWlu1SplKEEI9EX4", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "В поисках рая"),
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1Mg9bfPmczARpO_BNReFb0lS--ygYQWKz", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "Вечное лето"),
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1nF-RzvuywP0vvBxQQw21WEORxbcf7l2S", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "Качели"),
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1rcCbVoe11he3IecVK5soYhdaoUylkAVc", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "Три цвета"),
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1UoZSGUrEmbKXmh1vz4viq2tp7wwhOVVR", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "Ты или я"),
    .init(artist: "7раса", audio_url: "https://drive.google.com/uc?export=download&id=1b8mdnW9VsTk4AsIe01y8a5x3LFCqLkY7", cover: "https://drive.google.com/uc?export=download&id=1okM0wJHIasHmJFOGAkfMy6MtLRqVnr8-", title: "Черная весна")
]
