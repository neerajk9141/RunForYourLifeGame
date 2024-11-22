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

    private var isOnCeiling: Bool = false // Track whether the player is on the ceiling

    private var gameSpeed: Float = 0.064
    private var maxSpeed: Float = 0.02 // Fastest possible speed
    private var speedIncrement: Float = 0.0001 // How much the speed increases per frame

    
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
        
            // Add walls for closed space
//        addWalls()
        
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
        timer = Timer.publish(every: Double(gameSpeed), on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.updateGame()
                    self.updateSpeed() // Gradually increase speed
                }
            }
    }
    
    private func updateSpeed() {
        if gameSpeed > maxSpeed {
            gameSpeed -= speedIncrement // Decrease interval between frames
            timer?.cancel() // Restart the timer with the new speed
            startGame()
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
            road.position = [Float(index) * 10, -0.05, -5]
        }
        
            // Reset obstacles
        for obstacle in obstacles {
            obstacle.removeFromParent()
        }
        obstacles.removeAll()
        
            // Restart the game
        startGame()
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
        
//        updateRoad()
        updatePlayer()
        await updateObstacles()
        checkCollisions()
    }
    
    private func gameOver() {
        timer?.cancel()
        print("Game Over! Final Score: \(score)")
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
    
        // MARK: - Lighting
    private func addLighting() {
        let light = DirectionalLight()
        light.light.intensity = 1000
        light.light.color = .white
        light.position = [0, 5, -5]
        anchor.addChild(light)
    }
    

}

//MARK: Walls
extension GameManager {
    
    private func addWalls() {
        let wallThickness: Float = 0.2
        let wallHeight: Float = 5.0 // Increased to cover the larger distance
        let wallLength: Float = 48.0
        
        let leftWall = ModelEntity(mesh: .generateBox(size: [wallThickness, wallHeight, wallLength]))
        leftWall.position = [-5.5, 1.5, -5] // Centered between ground and ceiling
        leftWall.model?.materials = [SimpleMaterial(color: .darkGray, isMetallic: false)]
        
        let rightWall = ModelEntity(mesh: .generateBox(size: [wallThickness, wallHeight, wallLength]))
        rightWall.position = [5.5, 1.5, -5] // Centered between ground and ceiling
        rightWall.model?.materials = [SimpleMaterial(color: .darkGray, isMetallic: false)]
        
        let ceiling = ModelEntity(mesh: .generateBox(size: [5.0, wallThickness, wallLength]))
        ceiling.position = [0, 4.0, -5] // Raised for the new ceiling height
        ceiling.model?.materials = [SimpleMaterial(color: .darkGray, isMetallic: false)]
        
        let floor = ModelEntity(mesh: .generateBox(size: [5.0, wallThickness, wallLength]))
        floor.position = [0, -0.5, -5]
        floor.model?.materials = [SimpleMaterial(color: .darkGray, isMetallic: false)]
        
        anchor.addChild(leftWall)
        anchor.addChild(rightWall)
//        anchor.addChild(ceiling)
//        anchor.addChild(floor)
    }
    
}

//MARK: Player And Roads

extension GameManager {
    
        // MARK: - Road Scrolling
    @MainActor
    private func createRoads() async -> [Entity] {
        var roads = [Entity]()
        let roadLength: Float = 50.0 // Adjusted for better spacing
        
        for i in 0..<6 { // Create 6 road segments
            for yPosition in [0.0, 4.0] { // Increased the ceiling height to 3.0
                if let road = try? await Entity(named: "road", in: realityKitContentBundle) {
                    road.position = SIMD3<Float>(Float(i) * roadLength, Float(yPosition - 0.05), -5)
                    road.scale *= 1.2
                    road.transform.rotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0]) // Rotate road by 90 degrees
                    roads.append(road)
                }
            }
        }
        
        return roads
    }
    
    private func updateRoad() {
        let roadLength: Float = 0.1
        for road in roads {
            road.position.x -= 0.1
            if road.position.x < -roadLength { // Move road to the back of the loop
                road.position.x += roadLength * Float(roads.count / 2)
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
            player.transform.rotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
            player.generateCollisionShapes(recursive: true)
            return player
        }
        fatalError("Failed to load player model!")
    }
    
    private func updatePlayer() {
            // Prevent the player from falling
        if isOnCeiling {
            player.position.y = 3.9 // Stick to the ceiling
        } else {
            player.position.y = 0.0 // Stick to the ground
        }
    }
}

extension GameManager {
    
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
        textModel.position = [1, -1.5, -3] // Position above the player
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
        
        button.position = [-1, -0.8, -3] // Position it above the player
        button.name = "resetButton"
        
            // Add interaction
        button.generateCollisionShapes(recursive: true)
        button.components[InputTargetComponent.self] = InputTargetComponent()
        return button
    }
    
}

extension GameManager {
    
    @MainActor func jump() {
        guard !isJumping else { return }
        isJumping = true
        
            // Toggle between ground and ceiling
        toggleGravity()
        isJumping = false
    }
    
    
        // Toggle gravity between ground and ceiling
    @MainActor
    private func toggleGravity() {
        isOnCeiling.toggle()
        let targetY: Float = isOnCeiling ? 4.0 : 0.0 // Updated for new ceiling height
        let targetRotation = isOnCeiling ? simd_quatf(angle: .pi, axis: [1, 0, 0]) : simd_quatf(angle: 0, axis: [1, 0, 0])
        
        Task {
            await animateProperty(duration: 0.3) { progress in
                self.player.position.y = Float.lerp(from: self.player.position.y, to: targetY, t: progress)
                
                    // Maintain consistent orientation (facing forward)
                let forwardFacingRotation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0]) // Always facing forward
                self.player.transform.rotation = simd_slerp(forwardFacingRotation, targetRotation * forwardFacingRotation, progress)
            }
        }
    }
    
    func animateProperty(duration: Double, animation: @escaping (Float) -> Void) async {
        let frameRate: Double = 1 / 60 // 60 FPS
        let totalFrames = Int(duration / frameRate)
        for frame in 0...totalFrames {
            let progress = Float(frame) / Float(totalFrames)
            animation(progress)
            try? await Task.sleep(nanoseconds: UInt64(frameRate * 1_000_000_000)) // Sleep for frame duration
        }
    }
 
}


//MARK: Obstacles
extension GameManager {
    
    
        // Update obstacle creation to handle both ground and ceiling
    @MainActor
    private func createObstacle() async -> Entity {
        let yPosition: Float = isOnCeiling ? 3.0 : 0.01 // Slightly above the road surface for both ground and ceiling
        
        if let obstacle = await loadEntity(named: "obstacle", scale: 0.3, position: [5, yPosition, -5], animations: true) {
            return obstacle
        }
        fatalError("Failed to load obstacle model!")
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
                score += 10
            }
        }
    }
    
        // Update collision detection to handle ground and ceiling
    private func checkCollisions() {
        for obstacle in obstacles {
            let isColliding = abs(player.position.y - obstacle.position.y) < 0.1 // Match y-positions
            if player.position.distance(to: obstacle.position) < 0.3 {
                gameOver()
            }
        }
    }
    
}

