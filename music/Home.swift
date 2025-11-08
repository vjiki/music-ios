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
    
    var body: some View {
        header
    }
    
    // Header
    var header: some View {
        HStack {
            Text("Good morning moods")
        }
        .frame(width: .infinity, height: 60)
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
