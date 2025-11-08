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
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius : 0, style: .continuous)
                    .fill(.ultraThickMaterial)
                    .overlay {
                        Rectangle()
                            .fill(.gray.opacity(0.4))
                            .opacity(animateContent ? 1 : 0)
                    }
                    .overlay(alignment: .top) {
                        MusicInfo(expandSheet: $expandSheet, animation: animation)
                            .allowsHitTesting(false)
                            .opacity(animateContent ? 1 : 0)
                    }
                    .matchedGeometryEffect(id: "BACKGROUNDVIEW", in: animation)
                
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.clear]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 300)
                
                VStack(spacing: 15) {
                    HStack(alignment: .top) {
                        Image(systemName: "chevron.down")
                            .imageScale(.large)
                            .onTapGesture {
                                expandSheet.toggle()
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
                        Image("music 1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: animateContent ? 30 : 60, style: .continuous))
                    }
                    .matchedGeometryEffect(id: "SONGCOVER", in: animation)
                    .frame(width: size.width)
                    .padding(.vertical, size.height < 700 ? 30 : 40)
                    .padding(.horizontal)
                }
                .padding(.top, safeArea.top + (safeArea.bottom == 0 ? 10 : 0))
                .padding(.bottom, safeArea.bottom == 0 ? 10 : safeArea.bottom)
                .padding(.horizontal, 25)
                .frame(maxWidth: .infinity)
            }
        }
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
