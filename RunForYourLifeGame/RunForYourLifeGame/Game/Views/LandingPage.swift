//
//  LandingPage.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//

import RealityKit
import RealityKitContent
import SwiftUI

//struct LandingPage: View {
//    var body: some View {
//        RealityView { content, attachments in
//            let scene = createGameScene()
//            content.add(scene)
//        }
//        .ignoresSafeArea()
//    }
//    
//    
//    func createGameScene() -> Scene {
//        let scene = Scene()
//        
//            // Ground
//        let ground = createGround()
//        scene.addAnchor(ground)
//        
//            // Player
//        let player = createPlayer()
//        scene.addAnchor(player)
//        
//            // Obstacles (initial spawn)
//        let obstacles = createObstacles()
//        scene.addAnchor(obstacles)
//        
//        return scene
//    }
//    
//    func createGround() -> Entity {
//        let ground = ModelEntity(mesh: .generateBox(size: [100, 0.2, 10]))
//        ground.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
//        ground.position = [0, -1, 0]
//        return ground
//    }
//    
//    func createPlayer() -> Entity {
//        let player = ModelEntity(mesh: .generateSphere(radius: 0.5))
//        player.model?.materials = [SimpleMaterial(color: .blue, isMetallic: false)]
//        player.position = [0, 0, 0]
//        return player
//    }
//    
//    func createObstacles() -> AnchorEntity {
//        let anchor = AnchorEntity()
//        
//            // Create an obstacle
//        let obstacle = ModelEntity(mesh: .generateBox(size: [1, 1, 1]))
//        obstacle.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
//        obstacle.position = [5, 0, 0] // Adjust spawn position
//        
//        anchor.addChild(obstacle)
//        return anchor
//    }
//}
