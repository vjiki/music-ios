//
//  ContentView.swift
//  music
//
//  Created by Nikolai Golubkin on 15. 8. 2025..
//

import SwiftUI

struct Home: View {
    // Animation properties
    @State private var expandSheet = false
    @Namespace private var animation
    
    @EnvironmentObject var songManager: SongManager
    
    var body: some View {
        ScrollView {
            header
            
            TagsView()
            
            QuickPlay()
            
            LargeCards()
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    // Header
    var header: some View {
        GeometryReader {
            size in
            VStack(alignment: .leading) {
                HStack {
                    Text("Good morning moods")
                        .font(.title2)
                    
                    Spacer()
                    
                    Image(systemName: "bell")
                        .imageScale(.large)
                    
                    Image("singer 1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
            }
        }

        .padding(.horizontal)
        .padding(.top, getSafeAreaTop())
        .background(LinearGradient(colors: [Color.red, .clear], startPoint: .top, endPoint: .bottom))
        .frame(width: .infinity, height: getSafeAreaTop() * 2)
    }
    
    
    // Tags View
    @ViewBuilder func TagsView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(sampleTagList, id: \.id) { item in
                    Text(item.tag)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.15)))
                }
            }
            .padding()
        }
    }
    
    
    // Quick Play Songs
    @ViewBuilder func QuickPlay() -> some View {
        VStack {
            HStack {
                Text("Quick Play")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(60)), GridItem(.fixed(60)), GridItem(.fixed(60)), GridItem(.fixed(60))], content: {
                    // How List of Songs
                    ForEach(sampleSongs, id: \.id) { item in
                        HStack(spacing: 20, content: {
                            AsyncImage(url: URL(string: item.cover)) { img in
                                img.resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                                    .background(.white.opacity(0.1))
                                    .clipShape(.rect(cornerRadius: 5))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(.rect(cornerRadius: 5))

                            VStack(alignment: .leading) {
                                Text("\(item.title)")
                                    .font(.headline)
                                Text("\(item.artist)")
                                    .font(.caption)
                            }
                            
                            Spacer()
                        })
                        .onTapGesture {
                            songManager.playSong(item, in: sampleSongs)
                        }
                    }
                })
                 .padding(.horizontal)
             }
        }
    }
    
    // Large Cards View -> New Releases
    @ViewBuilder func LargeCards() -> some View {
        VStack {
            HStack {
                Text("New Releases")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15, content: {
                    ForEach(sampleSongs, id: \.id) { item in
                        VStack(alignment: .leading, content: {
                            AsyncImage(url: URL(string: item.cover)) { img in
                                img.resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 160, height: 160)
                            .clipShape(.rect(cornerRadius: 20))
                            
                            Text("\(item.title)")
                                .font(.headline)
                            
                            Text("\(item.artist)")
                                .font(.caption)
                        })
                        .onTapGesture {
                            songManager.playSong(item, in: sampleSongs)
                        }
                    }
                })
                .padding(.horizontal)
            }
        }
    }
    
    // Here we create a function to get Size of Top Safe Area
    func getSafeAreaTop() -> CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        return keyWindow?.safeAreaInsets.top ?? 0
    }
    
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
