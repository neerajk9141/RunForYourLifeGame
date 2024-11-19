//
//  ContentView.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    var body: some View {
        VStack {

            ToggleImmersiveSpaceButton()
            
//            RunnerGameView()
//                .gesture(DragGesture()
//                    .onEnded { value in
//                        if value.translation.height < 0 {
//                            handleSwipe(.up)
//                        } else if value.translation.height > 0 {
//                            handleSwipe(.down)
//                        }
//                    }
//                )
        }
        .padding()
    }
    
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
