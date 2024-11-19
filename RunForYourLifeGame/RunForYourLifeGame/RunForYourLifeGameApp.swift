//
//  RunForYourLifeGameApp.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 19/11/24.
//

import SwiftUI

@main
struct RunForYourLifeGameApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
            
//            RunnerGameView()
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
