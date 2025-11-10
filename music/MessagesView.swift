//
//  MessagesView.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import SwiftUI

struct MessagesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search bar
                searchBarView
                
                // Notes/Stories section
                notesSection
                
                // Messages section
                messagesSection
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Text("nezzabudka5")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            
            Spacer()
            
            Button {
                // Edit action
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Search Bar View
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.6))
                .padding(.leading, 12)
            
            TextField("Search", text: $searchText)
                .foregroundStyle(.white)
                .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Your note
                NoteItem(
                    profileImage: "person.crop.circle.fill",
                    bubbleText: "What's on your playlist?",
                    label: "Your note",
                    showLocationOff: true
                )
                
                // Other notes
                NoteItem(
                    profileImage: "person.crop.circle.fill",
                    bubbleText: "🧛",
                    label: "Anastasia Igna..."
                )
                
                NoteItem(
                    profileImage: "person.crop.circle.fill",
                    bubbleText: "🎶 Алло Teliga",
                    label: "Vlad Teliga"
                )
                
                NoteItem(
                    profileImage: "person.crop.circle.fill",
                    bubbleText: "🌍",
                    label: "World"
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Messages Section
    private var messagesSection: some View {
        VStack(spacing: 0) {
            // Messages header
            HStack {
                Text("Messages")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.leading, 8)
                
                Spacer()
                
                Button {
                    // Requests action
                } label: {
                    Text("Requests (1)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Messages list
            ScrollView {
                LazyVStack(spacing: 0) {
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "Шахрух Саттаров",
                        status: "2 new messages · 4h",
                        hasUnread: true
                    )
                    
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "Лампочка не выкручивается",
                        status: "Active yesterday"
                    )
                    
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "Galina Afonina",
                        status: "Active 21m ago"
                    )
                    
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "haz_coach",
                        status: "Active 36m ago",
                        hasStory: true
                    )
                    
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "Deep",
                        status: "Sent yesterday"
                    )
                    
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "DJA",
                        status: "Active 5h ago"
                    )
                    
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "mihail.kuritsyn",
                        status: "Active 5h ago"
                    )
                    
                    MessageRow(
                        profileImage: "person.crop.circle.fill",
                        name: "Vjiki Losev",
                        status: "Sent on Tuesday"
                    )
                }
            }
        }
    }
}

// MARK: - Note Item
private struct NoteItem: View {
    let profileImage: String
    let bubbleText: String
    let label: String
    var showLocationOff: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .top) {
                // Profile image
                Image(systemName: profileImage)
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(width: 70, height: 70)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                
                // Bubble
                if !bubbleText.isEmpty {
                    Text(bubbleText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .offset(y: -25)
                        .frame(maxWidth: 100)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(1)
            
            if showLocationOff {
                Text("Location off")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Message Row
private struct MessageRow: View {
    let profileImage: String
    let name: String
    let status: String
    var hasUnread: Bool = false
    var hasStory: Bool = false
    
    var body: some View {
        Button {
            // Open message
        } label: {
            HStack(spacing: 12) {
                // Profile image
                ZStack {
                    if hasStory {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 58, height: 58)
                    }
                    
                    Image(systemName: profileImage)
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 54, height: 54)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Name and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(status)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Unread indicator and camera
                HStack(spacing: 12) {
                    if hasUnread {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                    
                    Button {
                        // Camera action
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MessagesView()
        .preferredColorScheme(.dark)
}

