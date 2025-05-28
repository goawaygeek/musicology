//
//  Untitled.swift
//  Musicology
//
//  Created by Scott Brewer on 5/12/25.
//
import CoreML
import Vision
import UIKit

class DrawingClassifier {
    
    // MARK: - Properties
    private let model: VNCoreMLModel
    
    // MARK: - Initialization
    init() throws {
        // Load the model from the app bundle
        guard let modelURL = Bundle.main.url(forResource: "Musicology", withExtension: "mlmodelc") else {
            throw NSError(domain: "DrawingClassifierError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not found in bundle"])
        }
        
        self.model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
    }
    
    // MARK: - Classification Methods
    
    /// Classify a drawing synchronously with completion handler
    func classifyDrawing(_ paths: [UIBezierPath], completion: @escaping (Result<ClassificationResult, Error>) -> Void) {
        // First, render the paths to an image
        let drawingImage = renderPathsToImage(paths)
        
        // Convert UIImage to CIImage for Vision framework
        guard let ciImage = CIImage(image: drawingImage) else {
            completion(.failure(NSError(domain: "DrawingClassifierError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])))
            return
        }
        
        // Create a request for image classification
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Process the results
            guard let results = request.results as? [VNClassificationObservation],
                  !results.isEmpty else {
                completion(.failure(NSError(domain: "DrawingClassifierError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No classification results"])))
                return
            }
            
            // Convert Vision results to our custom format
            let classificationResults = results.map { observation in
                return ClassificationResult(
                    label: observation.identifier,
                    confidence: observation.confidence
                )
            }.sorted { $0.confidence > $1.confidence }
            
            if let topResult = classificationResults.first {
                completion(.success(topResult))
            } else {
                completion(.failure(NSError(domain: "DrawingClassifierError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to process results"])))
            }
        }
        
        // Create an image request handler
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        // Perform the request
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Classify a drawing asynchronously using Swift concurrency
    func classifyDrawing(_ paths: [UIBezierPath]) async throws -> ClassificationResult {
        return try await withCheckedThrowingContinuation { continuation in
            classifyDrawing(paths) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // FIXME: this errors on simulators and should be updated to shift away from the ML model
    // (it should probably fall back on the original non ML gesture recognition code)
    func classifyDrawingWithMultipleResults(_ paths: [UIBezierPath], maxResults: Int = 3) async throws -> [ClassificationResult] {
        return try await withCheckedThrowingContinuation { continuation in
            // First, render the paths to an image
            let drawingImage = renderPathsToImage(paths)
            
            // Convert UIImage to CIImage for Vision framework
            guard let ciImage = CIImage(image: drawingImage) else {
                continuation.resume(throwing: NSError(domain: "DrawingClassifierError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"]))
                return
            }
            
            // Create a request for image classification
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Process the results
                guard let results = request.results as? [VNClassificationObservation],
                      !results.isEmpty else {
                    continuation.resume(throwing: NSError(domain: "DrawingClassifierError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No classification results"]))
                    return
                }
                
                // Convert Vision results to our custom format
                let classificationResults = results.map { observation in
                    return ClassificationResult(
                        label: observation.identifier,
                        confidence: observation.confidence
                    )
                }.sorted { $0.confidence > $1.confidence }
                
                // Return top N results
                let topResults = Array(classificationResults.prefix(maxResults))
                continuation.resume(returning: topResults)
            }
            
            // Create an image request handler
            let handler = VNImageRequestHandler(ciImage: ciImage)
            
            // Perform the request
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Render Bezier paths to a normalized image for classification
    private func renderPathsToImage(_ paths: [UIBezierPath], size: CGSize = CGSize(width: 128, height: 128)) -> UIImage {
        // Create a context to draw in
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        // Get the context and set up drawing parameters
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        
        // Fill with white background
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        // Calculate the bounding box of all paths
        var combinedBounds = CGRect.zero
        for path in paths {
            if combinedBounds.isEmpty {
                combinedBounds = path.bounds
            } else {
                combinedBounds = combinedBounds.union(path.bounds)
            }
        }
        
        // Scale and translate to fit in the center with padding
        let padding: CGFloat = 10
        let availableSize = CGSize(
            width: size.width - (padding * 2),
            height: size.height - (padding * 2)
        )
        
        // Calculate scale factors to maintain aspect ratio
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0
        
        if combinedBounds.width > 0 {
            scaleX = availableSize.width / combinedBounds.width
        }
        if combinedBounds.height > 0 {
            scaleY = availableSize.height / combinedBounds.height
        }
        
        // Use the smaller scale to maintain aspect ratio
        let scale = min(scaleX, scaleY)
        
        // Calculate translation to center
        let translationX = padding + (availableSize.width - (combinedBounds.width * scale)) / 2 - combinedBounds.minX * scale
        let translationY = padding + (availableSize.height - (combinedBounds.height * scale)) / 2 - combinedBounds.minY * scale
        
        // Apply transformation
        context.translateBy(x: translationX, y: translationY)
        context.scaleBy(x: scale, y: scale)
        
        // Draw all paths
        UIColor.black.setStroke()
        for path in paths {
            let pathCopy = path.copy() as! UIBezierPath
            pathCopy.lineWidth = 3.0 / scale  // Adjust line width for scaling
            pathCopy.stroke()
        }
        
        // Get the image
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return UIImage()
        }
        
        return image
    }
}

// MARK: - Supporting Types

/// Represents a single classification result
struct ClassificationResult {
    let label: String
    let confidence: Float
    
    /// Confidence as percentage
    var confidencePercentage: Float {
        return confidence * 100
    }
    
    /// String representation of the result
    var description: String {
        return "\(label): \(String(format: "%.1f", confidencePercentage))%"
    }
}
