import Metal
import CoreML

public class SegmentAnything {
    public let device: MTLDevice
    private let commandQueue: MTLCommandQueue!
    private let imageProcessor: ImageProcessor
    
    private var width: Int!
    private var height: Int!
    
    private var encoder: edge_sam_3x_encoder! // input: 1 × 3 × 1024 × 1024 | output: 1 × 256 × 64 × 64
    public var imageEmbeddings: MLMultiArray!
    
    private var decoder: edge_sam_3x_decoder! // input: 1 × 256 × 64 × 64 | output: 1 × 4 × 256 × 256
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.imageProcessor = ImageProcessor(device: device,
                                             mean: SIMD3<Float>(123.675 / 255.0, 116.28 / 255.0, 103.53 / 255.0),
                                             std: SIMD3<Float>(58.395 / 255.0, 57.12 / 255.0, 57.375 / 255.0))
    }
    
    public func load() {
        self.imageProcessor.load()
        
        let modelConfiguration = MLModelConfiguration()
        modelConfiguration.computeUnits = .all
        
        self.encoder = try! edge_sam_3x_encoder(configuration: modelConfiguration)
        self.decoder = try! edge_sam_3x_decoder(configuration: modelConfiguration)
    }
    
    public func preprocess(image: MTLTexture) {
        self.width = image.width
        self.height = image.height
        let resizedImage = self.imageProcessor.preprocess(image: image, commandQueue: self.commandQueue)
        let encoderInput = edge_sam_3x_encoderInput(image: resizedImage)
        let encoderOutput = try! self.encoder.prediction(input: encoderInput)
        self.imageEmbeddings = encoderOutput.image_embeddings
    }
    
}
