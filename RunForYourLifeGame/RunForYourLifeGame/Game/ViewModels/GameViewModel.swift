//
//  GameViewModel.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//

import Foundation
import RealityKit

class GameViewModel: ObservableObject {
    @Published var score: Int = 0
    
    func spawnObstacles(anchor: AnchorEntity) {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let obstacle = ModelEntity(mesh: .generateBox(size: [1, 1, 1]))
            obstacle.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
            obstacle.position = [5, 0, 0] // Randomize x position
            anchor.addChild(obstacle)
        }
    }
    
//    func handleSwipe(_ direction: SwipeDirection) {
//        switch direction {
//        case .up:
//            player.move(to: [player.position.x, player.position.y + 1, player.position.z], relativeTo: nil)
//        case .down:
//            player.move(to: [player.position.x, player.position.y - 1, player.position.z], relativeTo: nil)
//        }
//    }
}





