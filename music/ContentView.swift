//
//  ContentView.swift
//  music
//
//  Created by Nikolai Golubkin on 15. 8. 2025..
//

import SwiftUI

struct ContentView: View {
    @State private var expandSheet = false
    @Namespace private var animation
    
    var body: some View {
        TabView {
            // Bottom Bar
            Home()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(.ultraThickMaterial, for: .tabBar)
            
            Text("Search")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            Text("Playlists")
                .tabItem {
                    Image(systemName: "play.rectangle.on.rectangle")
                    Text("Playlists")
                }
        }
        .tint(.white)
        .safeAreaInset(edge: .bottom) {
            CustomBottomSheet()
        }
        .overlay {
            if expandSheet {
                MusicView(expandSheet: $expandSheet, animation: animation)
            }
        }
    }
    
    @ViewBuilder
    func CustomBottomSheet() -> some View {
        ZStack {
            if expandSheet {
                Rectangle()
                    .fill(.clear)
            } else {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay {
                        MusicInfo(expandSheet: $expandSheet, animation: animation)
                    }
                    .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
                
            }
        }
        .frame(height: 80)
        .offset(y: -49)
        
    }
    
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
