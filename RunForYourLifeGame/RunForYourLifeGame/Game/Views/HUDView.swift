//
//  HUDView.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//

import SwiftUI
import Combine

struct HUDView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        Text("Score: \(Int(gameState.distance))")
            .font(.largeTitle)
            .padding()
    }
}
