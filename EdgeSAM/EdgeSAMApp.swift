//
//  EdgeSAMApp.swift
//  EdgeSAM
//
//  Created by I3T Duke on 7/25/24.
//

import SwiftUI

@main
struct EdgeSAMApp: App {

    @State private var appModel = AppModel()
    @State private var segmentAnything: SegmentAnything
    @State private var textureLoader: TextureLoader
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.segmentAnything = SegmentAnything(device: device)
        self.textureLoader = TextureLoader(device: device)
        self.segmentAnything.load()
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(segmentAnything: self.segmentAnything,
                        textureLoader: self.textureLoader)
                .environment(appModel)
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
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
