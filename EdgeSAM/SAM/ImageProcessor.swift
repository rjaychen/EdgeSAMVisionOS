import Metal
import CoreML

class ImageProcessor {
    private let device: MTLDevice!
    public var library: MTLLibrary!
    private let mean: SIMD3<Float>
    private let std: SIMD3<Float>
    private let inputSize: Int
    private let outputSize: Int
    
    private var originalWidth: Int!
    private var originalHeight: Int!
    
    private var resizedWidth: Int!
    private var resizedHeight: Int!
    
    private var preprocessComputePipelineState: MTLComputePipelineState!
    private var inputBuffer: MTLBuffer!
    
    private var postprocessComputePipelineState: MTLComputePipelineState!
        
    init(device: MTLDevice, mean: SIMD3<Float>, std: SIMD3<Float>) {
        self.device = device
        self.mean = mean
        self.std = std
        self.inputSize = 1024
        self.outputSize = 256
        self.preprocessComputePipelineState = nil
    }
    
    func load() {
        let library = self.device.makeDefaultLibrary()!
        let preprocessKernelFunction = library.makeFunction(name: "preprocessing_kernel")!
        let postprocessKernelFunction = library.makeFunction(name: "postprocessing_kernel")!
        self.preprocessComputePipelineState = try! self.device.makeComputePipelineState(function: preprocessKernelFunction)
        self.postprocessComputePipelineState = try! self.device.makeComputePipelineState(function: postprocessKernelFunction)
    }
    
    func preprocess(image: MTLTexture, commandQueue: MTLCommandQueue) -> MLMultiArray {
        self.originalWidth = image.width
        self.originalHeight = image.height
        
        let scale = Double(self.inputSize) / Double(max(self.originalWidth, self.originalHeight))
        self.resizedWidth = Int(Double(self.originalWidth) * scale + 0.5)
        self.resizedHeight = Int(Double(self.originalHeight) * scale + 0.5)
        let paddingX = self.inputSize - self.resizedWidth
        let paddingY = self.inputSize - self.resizedHeight
        
        let channels = 3
        let bytesPerChannel = MemoryLayout<Float>.stride * self.inputSize * self.inputSize // rgb square matrix of floats
        let bytesCount = channels * bytesPerChannel
        
        if self.inputBuffer == nil || self.inputBuffer.length != bytesCount {
            self.inputBuffer = self.device.makeBuffer(length: bytesCount, options: .storageModeShared)
        }
        
        var preprocessingInput = PreprocessingInput(mean: self.mean, 
                                                    std: self.std,
                                                    size: SIMD2<UInt32>(UInt32(self.resizedWidth), UInt32(self.resizedHeight)),
                                                    padding: SIMD2<UInt32>(UInt32(paddingX), UInt32(paddingY)))
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeCommandEncoder.setComputePipelineState(self.preprocessComputePipelineState)
        computeCommandEncoder.setTexture(image, index: 0)
        computeCommandEncoder.setBytes(&preprocessingInput, length: MemoryLayout<PreprocessingInput>.stride, index: 0)
        computeCommandEncoder.setBuffer(self.inputBuffer, offset: 0, attributeStride: MemoryLayout<Float>.stride, index: 1) //red
        computeCommandEncoder.setBuffer(self.inputBuffer, offset: 1 * bytesPerChannel, attributeStride: MemoryLayout<Float>.stride, index: 2)
        computeCommandEncoder.setBuffer(self.inputBuffer, offset: 2 * bytesPerChannel, attributeStride: MemoryLayout<Float>.stride, index: 3)
        
        let threadgroupSize = MTLSize(width: self.preprocessComputePipelineState.threadExecutionWidth,
                                      height: self.preprocessComputePipelineState.maxTotalThreadsPerThreadgroup / self.preprocessComputePipelineState.threadExecutionWidth,
                                      depth: 1)
        if self.device.supportsFamily(.common3) {
            computeCommandEncoder.dispatchThreads(
                MTLSize(width: self.resizedWidth, height: self.resizedHeight, depth: 1),
                threadsPerThreadgroup: threadgroupSize)
        } else {
            let gridSize = MTLSize(width: (self.resizedWidth + threadgroupSize.width - 1) / threadgroupSize.width,
                                   height: (self.resizedHeight + threadgroupSize.height - 1) / threadgroupSize.height,
                                   depth: 1)
            computeCommandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadgroupSize)
        }
        
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return try! MLMultiArray(
            dataPointer: self.inputBuffer.contents(),
            shape: [1, channels as NSNumber, self.inputSize as NSNumber, self.inputSize as NSNumber],
            dataType: .float32,
            strides: [(channels * inputSize * inputSize) as NSNumber,
                      (inputSize * inputSize) as NSNumber,
                      inputSize as NSNumber,
                      1]
        )
        
    }
    
}
