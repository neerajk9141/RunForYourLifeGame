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
            
        }
        .padding()
    }
    
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
