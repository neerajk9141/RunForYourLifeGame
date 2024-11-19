//
//  GameManger.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//
import SwiftUI
import RealityKitContent
import RealityKit
import Combine

class GameManager: ObservableObject {
    private var player: Entity!
    private var roads: [Entity] = []
    private var obstacles: [Entity] = []
    private var anchor = AnchorEntity()
    private var timer: AnyCancellable?
    private var isJumping: Bool = false
    private var scroeEntity: ModelEntity?
    
    @Published var score: Int = 0
    private var gameTime: Double = 0
    private var lastScore: Int = -1 // Cache to store the previous score

        // MARK: - Scene Setup
    @MainActor func setupScene(for content: RealityViewContent) {
        content.add(anchor)
        
            // Move the game world away from the origin
        anchor.position = [0, 0, -5]
        
            // Add lights for improved visuals
        addLighting()
        
            // Add road
        Task {
            roads = await createRoads()
            for road in roads {
                anchor.addChild(road)
            }
        }
        
            // Add player
        Task {
            player = await createPlayer()
            anchor.addChild(player)
        }
        
            // Add score display
        let scoreDisplay = createScoreDisplay()
        anchor.addChild(scoreDisplay)
        
            // Add reset button
        let resetButton = createResetButton()
        anchor.addChild(resetButton)
    }
    
    func startGame() {
        timer = Timer.publish(every: 0.032, on: .main, in: .common) // Smooth updates at 60 FPS
            .autoconnect()
            .sink { _ in
                Task {
                    await self.updateGame()
                }
            }
    }
    
    func resetGame() {
        timer?.cancel() // Stop the game loop
        
            // Reset state
        gameTime = 0
        score = 0
        lastScore = -1
        isJumping = false
        
            // Reset player position
        player.position = [-1.5, 0, -5]
        
            // Reset roads
        for (index, road) in roads.enumerated() {
            road.position = [Float(index) * 10, -0.5, -5]
        }
        
            // Reset obstacles
        for obstacle in obstacles {
            obstacle.removeFromParent()
        }
        obstacles.removeAll()
        
            // Restart the game
        startGame()
    }
    
    func jump() {
        guard !isJumping else { return } // Prevent multiple jumps
        isJumping = true
        
        let jumpHeight: Float = 1.0
        let totalDuration: Float = 0.8 // Total duration of the jump (up and down)
        let frameRate: Float = 1 / 60 // 60 FPS for smooth animation
        let upwardDuration: Float = totalDuration / 2 // Half for upward motion
        let downwardDuration: Float = totalDuration / 2
        
        var elapsedTime: Float = 0
        let originalPosition = player.position
        
            // Timer for frame-by-frame updates
        Timer.scheduledTimer(withTimeInterval: Double(frameRate), repeats: true) { timer in
            elapsedTime += frameRate
            
            if elapsedTime <= upwardDuration {
                    // Upward motion with ease-out
                let t = elapsedTime / upwardDuration
                let easedT = t * (2 - t) // Quadratic easing-out
                self.player.position.y = originalPosition.y + easedT * jumpHeight
            } else if elapsedTime <= totalDuration {
                    // Downward motion with ease-in
                let t = (elapsedTime - upwardDuration) / downwardDuration
                let easedT = t * t // Quadratic easing-in
                self.player.position.y = originalPosition.y + (1 - easedT) * jumpHeight
            } else {
                    // End of jump
                self.player.position.y = originalPosition.y
                self.isJumping = false
                timer.invalidate() // Stop the timer
            }
        }
    }
    
        // MARK: - Game Update Loop
    @MainActor
    private func updateGame() async {
        gameTime += 0.032
        score = Int(gameTime * 10)
        
            // Update score display only if score changes
        if score != lastScore {
            lastScore = score
            updateScoreDisplay()
        }
        
        updateRoad()
        updatePlayer()
        await updateObstacles()
        checkCollisions()
    }
    
    private func gameOver() {
        timer?.cancel()
        print("Game Over! Final Score: \(score)")
    }
    
        // MARK: - Road Scrolling
    @MainActor
    private func createRoads() async -> [Entity] {
        var roads = [Entity]()
        var roadLength: Float = 20.0 // Length of the road segment (adjust to match the model size)
        
        for i in 0..<3 { // Create 3 road segments
            if let road = try? await Entity(named: "road", in: realityKitContentBundle) {
                road.position = [Float(i) * roadLength, -0.5, -5]
                road.scale *= 2.5 // Ensure scaling matches the design
                road.transform.rotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0]) // Rotate correctly
                roads.append(road)
            }
        }
        
        return roads
    }
    
    private func updateRoad() {
        let roadLength: Float = 20.0 // Length of the road segment
        for road in roads {
            road.position.x -= 0.1
            if road.position.x < -roadLength { // Move road to the end of the loop when out of bounds
                road.position.x += roadLength * Float(roads.count)
            }
        }
    }
    
        // MARK: - Player
    @MainActor
    private func createPlayer() async -> Entity {
        
        if let player = await loadEntity(named: "player", scale: 10.0, position: [-1.5, 0, -5], animations: true) {
            player.components.set(InputTargetComponent())
            player.transform.rotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            return player
        }
        
        if let player = try? await Entity(named: "player", in: realityKitContentBundle) {
            player.position = [-1.5, 0, -5]
            player.scale *= 10.0
            player.generateCollisionShapes(recursive: true)
            return player
        }
        fatalError("Failed to load player model!")
    }
    
    private func updatePlayer() {
        if player.position.y > 0 {
            player.position.y -= 0.02 // Simulate gravity
        } else {
            isJumping = false
        }
    }
    
        // MARK: - Obstacles
    @MainActor
    private func createObstacle() async -> Entity {
        
        if let obstacle = await loadEntity(named: "obstacle", scale: 0.3, position: [5, 0, -5], animations: true) {
            return obstacle
        }
        
        if let obstacle = try? await Entity(named: "obstacle", in: realityKitContentBundle) {
            obstacle.position = [5, 0, -5]
            obstacle.generateCollisionShapes(recursive: true)
            return obstacle
        }
        fatalError("Failed to load obstacle model!")
    }
    
    @MainActor
    private func loadEntity(named name: String, scale: Float, position: SIMD3<Float>, animations: Bool = true) async -> Entity? {
        if let entity = try? await Entity(named: name, in: realityKitContentBundle) {
            entity.scale *= scale
            entity.position = position
            entity.generateCollisionShapes(recursive: true)
            if animations, let animation = entity.availableAnimations.first {
                entity.playAnimation(animation.repeat(count: 0))
            }
            return entity
        }
        return nil
    }
    
    @MainActor
    private func updateObstacles() async {
        if Int(gameTime * 10) % 20 == 0 {
            if obstacles.last?.position.x ?? 0 < 3 {
                let obstacle = await createObstacle()
                anchor.addChild(obstacle)
                obstacles.append(obstacle)
            }
        }
        
        for obstacle in obstacles {
            obstacle.position.x -= 0.1
            if obstacle.position.x < -5 {
                obstacle.removeFromParent()
                obstacles.removeAll { $0 == obstacle }
                score += 10 // Add points for passing an obstacle
            }
        }
    }
    
        // MARK: - Lighting
    private func addLighting() {
        let light = DirectionalLight()
        light.light.intensity = 1000
        light.light.color = .white
        light.position = [0, 5, -5]
        anchor.addChild(light)
    }
    
        // MARK: - Collision Detection
    private func checkCollisions() {
        for obstacle in obstacles {
            if player.position.distance(to: obstacle.position) < 0.3 {
                gameOver()
            }
        }
    }
    
    
    @MainActor
    private func createScoreDisplay() -> ModelEntity {
        let textMesh = MeshResource.generateText(
            "Score: 0",
            extrusionDepth: 0.02,
            font: .systemFont(ofSize: 1.0),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        textModel.name = "scoreDisplay"
        textModel.position = [0, 2.5, -5] // Position above the player
        self.scroeEntity = textModel
        return textModel
    }
    
    private func updateScoreDisplay() {
        if let scoreDisplay = anchor.children.compactMap({ $0 as? ModelEntity }).first(where: { $0.name == "scoreDisplay" }) {
            let newTextMesh = MeshResource.generateText(
                "Score: \(score)",
                extrusionDepth: 0.02,
                font: .systemFont(ofSize: 1.0),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            scoreDisplay.model = ModelComponent(mesh: newTextMesh, materials: scoreDisplay.model?.materials ?? [])
        }
    }
    
    @MainActor
    private func createResetButton() -> ModelEntity {
        let buttonMesh = MeshResource.generateBox(size: [0.5, 0.2, 0.05])
        let material = SimpleMaterial(color: .red, isMetallic: false)
        let button = ModelEntity(mesh: buttonMesh, materials: [material])
        
        button.position = [0, 2.0, -5] // Position it above the player
        button.name = "resetButton"
        
            // Add interaction
        button.generateCollisionShapes(recursive: true)
        button.components[InputTargetComponent.self] = InputTargetComponent()
        return button
    }
}

extension SIMD3 where Scalar == Float {
    func distance(to other: SIMD3<Float>) -> Float {
        return sqrt(pow(self.x - other.x, 2) + pow(self.y - other.y, 2) + pow(self.z - other.z, 2))
    }
}
