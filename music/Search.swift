//
//  Search.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI

struct Search: View {
    @State var searchText: String = ""
    @State var sampleSortList: [SongsModel] = []

    @EnvironmentObject var songManager: SongManager
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")

                TextField("Search", text: $searchText)
                    .onChange(of: searchText, perform: { value in
                        sampleSortList = sampleSongs.filter {
                            $0.title.contains(searchText) || $0.artist.contains(searchText)
                        }
                    })
            }
            .padding()
            .background(.white.opacity(0.2))
            .clipShape(Capsule())
            .padding(.horizontal)

            ScrollView {
                ForEach(sampleSortList) { item in
                    // Song list item content goes here
                    HStack {
                        AsyncImage(url: URL(string: item.cover)) { img in
                            img.resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(.rect(cornerRadius: 5))
                        
                        VStack(alignment: .leading, content: {
                            Text("\(item.title)")
                                .font(.headline)
                            
                            Text("\(item.artist)")
                                .font(.caption)
                        })
                        
                        Spacer()
                    }
                    .onTapGesture {
                        let playlist = sampleSortList.isEmpty ? sampleSongs : sampleSortList
                        songManager.playSong(item, in: playlist)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    Search()
        .preferredColorScheme(.dark)
}
