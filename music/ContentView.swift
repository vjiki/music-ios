//
//  ContentView.swift
//  music
//
//  Created by Nikolai Golubkin on 15. 8. 2025..
//

import SwiftUI

struct ContentView: View {
    enum Tab: Hashable, CaseIterable {
        case home
        case search
        case playlists
        case profile
    }
    
    @State private var expandSheet = false
    @Namespace private var animation
    @StateObject var songManager = SongManager()
    @State private var currentTab: Tab = .home
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        TabView(selection: $currentTab) {
            Home()
                .tag(Tab.home)
                .environmentObject(songManager)
            
            Search(expandSheet: $expandSheet, animation: animation)
                .tag(Tab.search)
                .environmentObject(songManager)
            
            PlaylistsView()
                .tag(Tab.playlists)
                .environmentObject(songManager)
            
            ProfileView()
                .tag(Tab.profile)
                .environmentObject(songManager)
        }
        .background(Color.black.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if !songManager.song.title.isEmpty {
                    MiniPlayer()
                        .padding(.horizontal, 18)
                        .padding(.bottom, 8)
                }
                
                CustomTabBar(currentTab: $currentTab)
            }
            .opacity(expandSheet ? 0 : 1)
            .allowsHitTesting(!expandSheet)
        }
        .overlay {
            if expandSheet {
                ZStack {
                    // Opaque black background to hide content behind
                    Color.black
                        .ignoresSafeArea()
                    
                    MusicView(expandSheet: $expandSheet, animation: animation)
                        .environmentObject(songManager)
                }
            }
        }
    }
    
    @ViewBuilder
    private func MiniPlayer() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.24), radius: 10, x: 0, y: 6)
                .overlay {
                    MusicInfo(expandSheet: $expandSheet, animation: animation)
                        .environmentObject(songManager)
                        .padding(.horizontal, 10)
                }
        }
        .frame(height: 58)
        .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
    }
    
    private struct CustomTabBar: View {
        @Binding var currentTab: Tab
        
        private let items: [TabItem] = [
            TabItem(tab: .home, icon: "house", selectedIcon: "house.fill"),
            TabItem(tab: .search, icon: "magnifyingglass", selectedIcon: "magnifyingglass"),
            TabItem(tab: .playlists, icon: "play.square", selectedIcon: "play.square.fill"),
            TabItem(tab: .profile, icon: "person.crop.circle", selectedIcon: "person.crop.circle.fill")
        ]
        
        var body: some View {
            HStack {
                ForEach(items) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            currentTab = item.tab
                        }
                    } label: {
                        Image(systemName: iconName(for: item.tab))
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(currentTab == item.tab ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.95))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 0.5),
                alignment: .top
            )
        }
        
        private func iconName(for tab: Tab) -> String {
            guard let item = items.first(where: { $0.tab == tab }) else {
                return "circle"
            }
            return currentTab == tab ? item.selectedIcon : item.icon
        }
        
        private struct TabItem: Identifiable {
            let tab: Tab
            let icon: String
            let selectedIcon: String
            var id: Tab { tab }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
