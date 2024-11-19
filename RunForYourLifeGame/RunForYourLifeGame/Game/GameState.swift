//
//  GameState.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//

import SwiftUI

@MainActor
class GameState: ObservableObject {
    @Published var distance: Double = 0
    
    func updateDistance() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.distance += 0.1
        }
    }
}
