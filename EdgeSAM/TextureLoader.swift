import Foundation
import Metal
import MetalKit

class TextureLoader {
    private let ciContext: CIContext
    private let textureLoader: MTKTextureLoader
      
    init(device: MTLDevice) {
        self.ciContext = CIContext(mtlDevice: device)
        self.textureLoader = MTKTextureLoader(device: device)
    }
  
    func loadTexture(uiImage: UIImage) async throws -> MTLTexture {
        guard let ciImage = CIImage(
            image: uiImage,
            options: [
                .applyOrientationProperty: true,
                .properties: [kCGImagePropertyOrientation: CGImagePropertyOrientation(uiImage.imageOrientation).rawValue]
            ]
        ), let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent)
        else { throw NSError() }
    
    #if targetEnvironment(simulator)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
          pixelFormat: .bgra8Unorm,
          width: Int(ciImage.extent.width),
          height: Int(ciImage.extent.height),
          mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .shared
        
        let texture = self.textureLoader.device.makeTexture(descriptor: textureDescriptor)!
        
        self.ciContext.render(
          ciImage,
          to: texture,
          commandBuffer: nil,
          bounds: ciImage.extent,
          colorSpace: ciContext.workingColorSpace ?? CGColorSpaceCreateDeviceRGB()
        )
    
    return texture
    #endif
        
    return try await self.textureLoader.newTexture(
      cgImage: cgImage,
      options: [
        .textureStorageMode: MTLStorageMode.shared.rawValue
      ]
    )
  }
  
  func unloadTexture(texture: MTLTexture) -> UIImage {
    let ciImage = CIImage(mtlTexture: texture)!
      let transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1).translatedBy(x: 0, y: ciImage.extent.height)
    let transformed = ciImage.transformed(by: transform)
    
    let cgImage = self.ciContext.createCGImage(transformed, from: transformed.extent)!
    return UIImage(cgImage: cgImage)
  }
}

fileprivate extension CGImagePropertyOrientation {
  init(_ uiOrientation: UIImage.Orientation) {
    switch uiOrientation {
      case .up: self = .up
      case .upMirrored: self = .upMirrored
      case .down: self = .down
      case .downMirrored: self = .downMirrored
      case .left: self = .left
      case .leftMirrored: self = .leftMirrored
      case .right: self = .right
      case .rightMirrored: self = .rightMirrored
      @unknown default: self = .up
    }
  }
}
