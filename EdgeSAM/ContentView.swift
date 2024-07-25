//
//  ContentView.swift
//  EdgeSAM
//
//  Created by I3T Duke on 7/25/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    let segmentAnything: SegmentAnything
    let textureLoader: TextureLoader
    @State private var inputImage: UIImage = UIImage(named: "cameraframe")!
    
    var body: some View {
        VStack {
            Image(uiImage: inputImage)
                .resizable()
                .scaledToFit()
            Button("Segment") {
                Task(priority: .high) {
                    let imageTexture = try! await self.textureLoader.loadTexture(uiImage: inputImage)
                    self.segmentAnything.preprocess(image: imageTexture)
                    //print(self.segmentAnything.imageEmbeddings!)
                }
            }
        }
        .padding()
    }
}

//#Preview(windowStyle: .automatic) {
//    ContentView().environment(AppModel())
//}
