//
//  Search.swift
//  music
//
//  Created by Nikolai Golubkin on 11/8/25.
//

import SwiftUI

struct Search: View {
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    
    @State var searchText: String = ""
    @State var sampleSortList: [SongsModel] = []

    @EnvironmentObject var songManager: SongManager
    
    private var displayedSongs: [SongsModel] {
        if searchText.isEmpty {
            return songManager.librarySongs
        } else {
            return sampleSortList
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.6))
                    
                    TextField("Search", text: $searchText)
                        .foregroundStyle(.white)
                        .onChange(of: searchText, perform: { value in
                            sampleSortList = songManager.librarySongs.filter {
                                $0.title.localizedCaseInsensitiveContains(searchText) ||
                                $0.artist.localizedCaseInsensitiveContains(searchText)
                            }
                        })
                }
                .padding()
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Tracks list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayedSongs) { item in
                            TrackRow(song: item) {
                                songManager.playSong(item, in: displayedSongs)
                                expandSheet = true
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Tracks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Back action if needed
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Menu action
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}

private struct TrackRow: View {
    let song: SongsModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Album art
                AsyncImage(url: URL(string: song.cover)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                        .tint(.white.opacity(0.6))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Options button
                Button {
                    // Options action
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @Namespace var animation
        
        var body: some View {
            Search(expandSheet: .constant(false), animation: animation)
                .preferredColorScheme(.dark)
                .environmentObject(SongManager())
        }
    }
    
    return PreviewWrapper()
}
