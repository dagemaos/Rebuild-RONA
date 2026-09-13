//
//  ContentView.swift
//  RONA-Rebuild
//
//  Created by Ivanri Fleri Simanjuntak on 13/09/26.
//

import SwiftUI

struct ContentView: View {
    let container: AppContainer
    @State private var isShowingScanner = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "face.dashed")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Text("RONA Rebuild")
                .font(.largeTitle.bold())
            
            Button("Start Face Scan") {
                isShowingScanner = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .fullScreenCover(isPresented: $isShowingScanner) {
            container.makeScanView(onDismiss: {
                isShowingScanner = false
            })
        }
    }
}

#Preview {
    ContentView(container: AppContainer())
}
