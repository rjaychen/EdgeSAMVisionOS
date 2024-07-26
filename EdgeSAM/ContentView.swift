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
    let maskProcessor: MaskProcessor
    
    @State private var inputImage: UIImage = UIImage(named: "cameraframe")!
    @State private var resultImage: UIImage?
    @State private var countX: Int = 0
    @State private var countY: Int = 0
    
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
                    
                    let masks = self.segmentAnything.predictMask(points: [Point(x: Float(1499), y: Float(540), label: 1)])
                    //let maskTexture = self.maskProcessor.apply(input: imageTexture, mask: masks.first!, mode: .subtractive)
                    let uiImage = self.textureLoader.unloadTexture(texture: masks.first!)
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
