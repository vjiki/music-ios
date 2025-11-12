//
//  SettingsView.swift
//  music
//
//  Created by Nikolai Golubkin on 11/9/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var songManager: SongManager
    @EnvironmentObject var authService: AuthService
    
    @State private var searchText = ""
    @State private var showLoginView = false
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    @State private var showDataAndStorage = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Your account section
                    yourAccountSection
                    
                    // How you use Music section
                    howYouUseSection
                    
                    // Who can see your content section
                    whoCanSeeSection
                    
                    // How others can interact with you section
                    howOthersInteractSection
                    
                    // What you see section
                    whatYouSeeSection
                    
                    // Your app and media section
                    yourAppAndMediaSection
                    
                    // Family Centre section
                    familyCentreSection
                    
                    // Your insights and tools section
                    yourInsightsSection
                    
                    // Your orders and fundraisers section
                    ordersSection
                    
                    // More info and support section
                    moreInfoSection
                    
                    // Also from Meta section
                    alsoFromMetaSection
                    
                    // Login section
                    loginSection
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Settings and activity")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.6))
            
            TextField("Search", text: $searchText)
                .foregroundStyle(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Your Account Section
    private var yourAccountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your account")
            
            SettingsRow(
                icon: "person.circle",
                title: "Accounts Centre",
                subtitle: "Password, security, personal details, ad preferences",
                trailing: {
                    HStack(spacing: 8) {
                        Text("∞ Meta")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            
            Text("Manage your connected experiences and account settings across Meta technologies. Learn more")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
        }
    }
    
    // MARK: - How You Use Section
    private var howYouUseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "How you use Music")
            
            SettingsRow(icon: "bookmark", title: "Saved")
            SettingsRow(icon: "arrow.counterclockwise", title: "Archive")
            SettingsRow(icon: "chart.line.uptrend.xyaxis", title: "Your activity")
            SettingsRow(icon: "bell", title: "Notifications")
            SettingsRow(icon: "clock", title: "Time management")
            SettingsRow(
                icon: "music.note",
                title: "Update Music",
                trailing: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
        }
    }
    
    // MARK: - Who Can See Section
    private var whoCanSeeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Who can see your content")
            
            SettingsRow(
                icon: "lock",
                title: "Account privacy",
                trailing: {
                    HStack(spacing: 8) {
                        Text("Public")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            
            SettingsRow(
                icon: "star",
                title: "Close Friends",
                trailing: {
                    HStack(spacing: 8) {
                        Text("0")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            
            SettingsRow(icon: "square.on.square", title: "Crossposting")
            SettingsRow(
                icon: "nosign",
                title: "Blocked",
                trailing: {
                    HStack(spacing: 8) {
                        Text("0")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            SettingsRow(icon: "mappin.slash", title: "Story and location")
            SettingsRow(icon: "person.2", title: "Activity in Friends tab")
        }
    }
    
    // MARK: - How Others Interact Section
    private var howOthersInteractSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "How others can interact with you")
            
            SettingsRow(icon: "message.waveform", title: "Messages and story replies")
            SettingsRow(icon: "at", title: "Tags and mentions")
            SettingsRow(icon: "bubble.left", title: "Comments")
            SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Sharing and reuse")
            SettingsRow(
                icon: "nosign",
                title: "Restricted",
                trailing: {
                    HStack(spacing: 8) {
                        Text("0")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            SettingsRow(
                icon: "exclamationmark.circle",
                title: "Limit interactions",
                trailing: {
                    HStack(spacing: 8) {
                        Text("Off")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            SettingsRow(icon: "textformat", title: "Hidden words")
            SettingsRow(icon: "person.badge.plus", title: "Follow and invite friends")
        }
    }
    
    // MARK: - What You See Section
    private var whatYouSeeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "What you see")
            
            SettingsRow(
                icon: "star",
                title: "Favourites",
                trailing: {
                    HStack(spacing: 8) {
                        Text("0")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            
            SettingsRow(
                icon: "bell.slash",
                title: "Muted accounts",
                trailing: {
                    HStack(spacing: 8) {
                        Text("0")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            
            SettingsRow(icon: "video.circle", title: "Content preferences")
            SettingsRow(icon: "heart.slash", title: "Like and share counts")
            SettingsRow(icon: "crown", title: "Subscriptions")
        }
    }
    
    // MARK: - Your App and Media Section
    private var yourAppAndMediaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your app and media")
            
            SettingsRow(icon: "iphone", title: "Device permissions")
            SettingsRow(icon: "arrow.down.circle", title: "Archiving and downloading")
            
            // Data and Storage row with green icon
            Button {
                showDataAndStorage = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.green)
                        .frame(width: 24, height: 24)
                    
                    Text("Data and Storage")
                        .font(.body)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            SettingsRow(icon: "person.circle", title: "Accessibility")
            SettingsRow(icon: "bubble.left.and.bubble.right", title: "Language and translations")
            SettingsRow(icon: "chart.bar", title: "Media quality")
            SettingsRow(icon: "desktopcomputer", title: "App website permissions")
        }
    }
    
    // MARK: - Family Centre Section
    private var familyCentreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Family Centre")
            
            SettingsRow(icon: "house.fill", title: "Supervision for Teen Accounts")
        }
    }
    
    // MARK: - Your Insights Section
    private var yourInsightsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your insights and tools")
            
            SettingsRow(icon: "star.circle", title: "Your dashboard")
            SettingsRow(icon: "chart.bar.fill", title: "Account type and tools")
            SettingsRow(
                icon: "checkmark.seal",
                title: "Music Verified",
                trailing: {
                    HStack(spacing: 8) {
                        Text("Not subscribed")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
        }
    }
    
    // MARK: - Orders Section
    private var ordersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your orders and fundraisers")
            
            SettingsRow(icon: "doc.text", title: "Orders and payments")
        }
    }
    
    // MARK: - More Info Section
    private var moreInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "More info and support")
            
            SettingsRow(icon: "questionmark.circle", title: "Help")
            SettingsRow(icon: "shield.checkered", title: "Privacy Centre")
            SettingsRow(icon: "person.2", title: "Account Status")
            SettingsRow(icon: "info.circle", title: "About")
        }
    }
    
    // MARK: - Also From Meta Section
    private var alsoFromMetaSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Also from Meta")
            
            SettingsRow(
                icon: "message.fill",
                title: "WhatsApp",
                subtitle: "Message privately with friends and family"
            )
            
            SettingsRow(
                icon: "square.stack",
                title: "Edits",
                subtitle: "Create videos with powerful editing tools",
                trailing: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            )
            
            SettingsRow(
                icon: "at",
                title: "Threads",
                subtitle: "Share ideas and join conversations"
            )
            
            SettingsRow(
                icon: "f.circle.fill",
                title: "Facebook",
                subtitle: "Explore things that you love"
            )
            
            SettingsRow(
                icon: "bolt.message.fill",
                title: "Messenger",
                subtitle: "Chat and share seamlessly with friends"
            )
        }
    }
    
    // MARK: - Login Section
    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Login")
            
            if authService.isAuthenticated {
                // User is logged in - show user info and logout button
                if let user = authService.currentUser {
                    // User info section
                    HStack(spacing: 12) {
                        if let avatarUrl = user.avatarUrl, !avatarUrl.isEmpty {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                                    .tint(.white.opacity(0.6))
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.nickname ?? user.name ?? "User")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                // Logout button
                Button {
                    showLogoutConfirmation = true
                } label: {
                    HStack {
                        if isLoggingOut {
                            ProgressView()
                                .tint(.red)
                        } else {
                            Text("Log out")
                                .font(.body)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .disabled(isLoggingOut)
            } else {
                // User is not logged in - show add account button
                Button {
                    showLoginView = true
                } label: {
                    Text("Add account")
                        .font(.body)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
        }
        .sheet(isPresented: $showLoginView) {
            LoginView()
                .environmentObject(authService)
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            // Dismiss SettingsView when authentication succeeds
            if isAuthenticated {
                showLoginView = false
            }
        }
        .sheet(isPresented: $showDataAndStorage) {
            DataAndStorageView()
                .environmentObject(songManager)
        }
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                Task {
                    isLoggingOut = true
                    await authService.signOut()
                    isLoggingOut = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// MARK: - Section Header
private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
}

// MARK: - Settings Row
private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let trailingView: AnyView?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailingView = nil
    }
    
    init<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailingView = AnyView(trailing())
    }
    
    var body: some View {
        Button {
            // Action
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.white)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if let trailingView {
                    trailingView
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
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
    SettingsView()
        .preferredColorScheme(.dark)
        .environmentObject(SongManager())
        .environmentObject(AuthService())
}

