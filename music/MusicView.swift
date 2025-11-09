//
//  MusicView.swift
//  music
//
//  Created by Nikolai Golubkin on 16. 8. 2025..
//

import SwiftUI

struct MusicView: View {
    
    @Binding var expandSheet: Bool
    var animation: Namespace.ID
    // View Properties
    @State private var animateContent: Bool = false
    @State private var offsetY: CGFloat = 0
    
    @EnvironmentObject var songManager: SongManager
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                    .fill(.black)
                    .overlay {
                        Rectangle()
                            .fill(.black)
                            .opacity(animateContent ? 1 : 0)
                    }
                    .overlay(alignment: .top) {
                        MusicInfo(expandSheet: $expandSheet, animation: animation)
                            .allowsHitTesting(false)
                            .opacity(animateContent ? 0 : 1)
                    }
                    .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
                
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.clear]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 300)
                
                VStack(spacing: 10) {
                    HStack(alignment: .top) {
                        Image(systemName: "chevron.down")
                            .imageScale(.large)
                            .onTapGesture {
                                expandSheet = false
                                animateContent = false
                            }
                        
                        Spacer()
                        
                        VStack(alignment: .center, content: {
                            Text("Playlist from album")
                                .opacity(0.5)
                                .font(.caption)
                            
                            Text("Top Hits")
                                .font(.title2)
                        })
                        
                        Spacer()
                        
                        Image(systemName: "ellipsis")
                            .imageScale(.large)
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 80)
                    
                    GeometryReader {
                        let size = $0.size
                        AsyncImage(url: URL(string: songManager.song.cover)) { img in
                            img.resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                                .background(.white.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 5))
                        }
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: animateContent ? 30 : 60, style: .continuous))
                    }
                    .matchedGeometryEffect(id: "SONGCOVER", in: animation)
                    .frame(width: size.width - 50)
                    .padding(.vertical, size.height < 700 ? 30 : 40)
                    
                    PlayerView(size)
                        .offset(y: animateContent ? 0 : size.height)
                }
                .padding(.top, safeArea.top + (safeArea.bottom == 0 ? 10 : 0))
                .padding(.bottom, safeArea.bottom == 0 ? 10 : safeArea.bottom)
                .padding(.horizontal, 25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .contentShape(Rectangle())
            .offset(y: offsetY)
            .gesture(
                DragGesture()
                    .onChanged( { value in
                        let translationY = value.translation.height
                        offsetY = (translationY > 0 ? translationY : 0)
                        
                    }).onEnded( { value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if offsetY > size.height * 0.4 {
                                expandSheet = false
                                animateContent = false
                            } else {
                                offsetY = .zero
                            }
                        }
                    })
            ).ignoresSafeArea(.container, edges: .all)
            
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear() {
            withAnimation(.easeInOut(duration: 0.35)) {
                animateContent = true
            }
        }
    }
    @ViewBuilder
    func PlayerView(_ mainSize: CGSize) -> some View {
        GeometryReader {
            let size = $0.size
            let spacing = size.height * 0.04
            
            // sizing t for more compact look
            VStack(spacing: spacing, content: {
                VStack(spacing: spacing, content: {
                    VStack(alignment: .center, spacing: 15, content: {
                        VStack(alignment: .center, spacing: 10, content: {
                            Text(songManager.song.title)
                                .font(.title)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text(songManager.song.artist)
                                .font(.title3)
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                        })
                        .frame(maxWidth: .infinity)
                        
                        Slider(
                            value: Binding(
                                get: {
                                    songManager.duration > 0 ? songManager.currentTime : 0
                                },
                                set: { newValue in
                                    songManager.seek(to: newValue)
                                }
                            ),
                            in: 0...(songManager.duration > 0 ? songManager.duration : 1),
                            step: 1
                        )
                        .disabled(songManager.duration == 0)
                        .tint(.white)
                        
                        HStack {
                            Text(songManager.formattedCurrentTime)
                                .font(.caption)
                                .monospacedDigit()
                            
                            Spacer()
                            
                            Text(songManager.formattedDuration)
                                .font(.caption)
                                .monospacedDigit()
                        }
                        .foregroundStyle(.gray)
                        
                        controlButtonsLayout()
                    })
                })
            })
        }
    }
    
    // MARK: - Control Buttons
    
    @ViewBuilder
    private func controlButtonsLayout() -> some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                horizontalControlButtons(spacing: 20)
                verticalControlButtons()
            }
        } else {
            horizontalControlButtons(spacing: 18)
        }
    }
    
    @ViewBuilder
    private func horizontalControlButtons(spacing: CGFloat) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            dislikeButton()
            shuffleButton()
            previousButton()
            playPauseButton()
            nextButton()
            repeatButton()
            likeButton()
        }
    }
    
    @ViewBuilder
    private func verticalControlButtons() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                dislikeButton()
                shuffleButton()
                previousButton()
            }
            
            playPauseButton()
                .padding(.vertical, 6)
            
            HStack(spacing: 20) {
                nextButton()
                repeatButton()
                likeButton()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func dislikeButton() -> some View {
        Button(action: {
            songManager.toggleDislike()
        }) {
            Image(systemName: songManager.dislikeIconName)
                .imageScale(.medium)
                .foregroundStyle(songManager.isCurrentSongDisliked ? Color.red : .gray)
        }
        .accessibilityLabel(songManager.isCurrentSongDisliked ? "Remove dislike" : "Dislike song")
    }
    
    @ViewBuilder
    private func shuffleButton() -> some View {
        Button(action: {
            songManager.toggleShuffle()
        }) {
            Image(systemName: "shuffle")
                .imageScale(.medium)
                .foregroundStyle(songManager.isShuffling ? .white : .gray)
        }
        .accessibilityLabel(songManager.isShuffling ? "Disable shuffle" : "Enable shuffle")
    }
    
    @ViewBuilder
    private func previousButton() -> some View {
        Button(action: {
            songManager.playPrevious()
        }) {
            Image(systemName: "backward.end.fill")
                .imageScale(.medium)
        }
        .accessibilityLabel("Previous song")
    }
    
    @ViewBuilder
    private func playPauseButton() -> some View {
        Button(action: {
            songManager.togglePlayPause()
        }) {
            Image(systemName: songManager.isPlaying ? "pause.fill" : "play.fill")
                .imageScale(.large)
                .padding()
                .background(.white)
                .clipShape(Circle())
                .foregroundStyle(.black)
        }
        .accessibilityLabel(songManager.isPlaying ? "Pause" : "Play")
    }
    
    @ViewBuilder
    private func nextButton() -> some View {
        Button(action: {
            songManager.playNext()
        }) {
            Image(systemName: "forward.end.fill")
                .imageScale(.medium)
        }
        .accessibilityLabel("Next song")
    }
    
    @ViewBuilder
    private func repeatButton() -> some View {
        Button(action: {
            songManager.cycleRepeatMode()
        }) {
            Image(systemName: songManager.repeatIconName)
                .imageScale(.medium)
                .foregroundStyle(songManager.repeatMode == .none ? .gray : .white)
        }
        .accessibilityLabel("Change repeat mode")
    }
    
    @ViewBuilder
    private func likeButton() -> some View {
        Button(action: {
            songManager.toggleLike()
        }) {
            Image(systemName: songManager.likeIconName)
                .imageScale(.medium)
                .foregroundStyle(songManager.isCurrentSongLiked ? Color.pink : .gray)
        }
        .accessibilityLabel(songManager.isCurrentSongLiked ? "Remove like" : "Like song")
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}

extension View {
    var deviceCornerRadius: CGFloat {
        let key = "_displayCornerRadius"
        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen {
            if let cornerRadius = screen.value(forKey: key) as? CGFloat {
                return cornerRadius
            }
            return 0
        }
        return 0
    }
}
