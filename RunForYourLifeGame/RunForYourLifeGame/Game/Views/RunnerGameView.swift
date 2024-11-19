//
//  Untitled.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//
import SwiftUI
import RealityKit
import RealityKitContent

struct RunnerGameView: View {
    @StateObject private var gameManager = GameManager()
    
    var body: some View {
        ZStack {
            RealityView { content in
                gameManager.setupScene(for: content)
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        if value.entity.name == "resetButton" {
                            gameManager.resetGame()
                        } else {
                            gameManager.jump()
                        }
                    }
            )
            .ignoresSafeArea()
                // Score HUD
            Text("Score: \(gameManager.score)")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .position(x: 100, y: 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                gameManager.startGame()
            }
        }
    }
}
