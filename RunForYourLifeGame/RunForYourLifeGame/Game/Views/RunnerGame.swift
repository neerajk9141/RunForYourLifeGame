//
//  RunnerGame.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//
import SwiftUI
import RealityKit


struct SideRunnerGame: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        ZStack {
            RunnerGameView()
            HUDView(gameState: gameState)
        }
        .onAppear {
            gameState.updateDistance()
        }
    }
}
