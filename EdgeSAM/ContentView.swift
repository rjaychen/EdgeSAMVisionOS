//
//  ContentView.swift
//  EdgeSAM
//
//  Created by I3T Duke on 7/25/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import CoreML

struct ContentView: View {
    
    let segmentAnything: SegmentAnything
    let textureLoader: TextureLoader
    @State private var inputImage: UIImage = UIImage(named: "cameraframe")!
    @State private var resultImage: UIImage?
    
    var body: some View {
        VStack {
            Image(uiImage: inputImage)
                .resizable()
                .scaledToFit()
            if let image = resultImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            Button("Segment") {
                Task(priority: .high) {
                    let imageTexture = try! await self.textureLoader.loadTexture(uiImage: inputImage)
                    self.segmentAnything.preprocess(image: imageTexture)
                    let masks = self.segmentAnything.predictMask(points: [(100.0, 100.0, 1)])
                    let ciImage = CIImage(mtlTexture: masks.first!)
                    let uiImage = UIImage(ciImage: ciImage!)
                    resultImage = uiImage
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
