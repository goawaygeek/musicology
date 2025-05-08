//
//  RecognizablePath.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//

import UIKit

enum ItemType: String {
    case emitter    // +
    case spring     // s
    case blackhole  // o
    case splitter   // triangle
    case drum       // U
    case cymbal     // =
    case note       // -
}

// Class to manage multiple paths for recognition with timer
class ShapeRecognizer {
    private var recentPaths: [UIBezierPath] = []
    private let maxPathsToStore = 3  // Store recent paths for multi-stroke recognition
    private var recognitionTimer: Timer?
    private let recognitionDelay: TimeInterval = 1.0 // 1 second delay
    
    // Closure to be called when a shape is recognized, can accept nil if NO shape is recognised.
    var onShapeRecognized: ((ItemType?) -> Void)?
    
    // Call this when a new path/stroke is started
    func beginPath() {
        // Cancel any pending recognition when a new stroke starts
        cancelRecognitionTimer()
    }
    
    // Call this when a path/stroke is completed
    func addPath(_ path: UIBezierPath) {
        recentPaths.append(path)
        if recentPaths.count > maxPathsToStore {
            recentPaths.removeFirst()
        }
        
        // Start the recognition timer
        startRecognitionTimer()
    }
    
    private func startRecognitionTimer() {
        // Cancel any existing timer first
        cancelRecognitionTimer()
        
        // Create a new timer
        recognitionTimer = Timer.scheduledTimer(
            timeInterval: recognitionDelay,
            target: self,
            selector: #selector(recognitionTimerFired),
            userInfo: nil,
            repeats: false
        )
    }
    
    private func cancelRecognitionTimer() {
        recognitionTimer?.invalidate()
        recognitionTimer = nil
    }
    
    @objc private func recognitionTimerFired() {
        // Timer expired, attempt recognition
        let recognizedType = recognizeShape()
        
        // Call the closure with the recognized shape
        onShapeRecognized?(recognizedType)
    
        // Clear paths after recognition (whether successful or not)
        clearPaths()
    }
    
    func recognizeShape() -> ItemType? {
        // First try single-path recognition
        print("recognising shape!")
        if recentPaths.count >= 2 {
            // Try to recognize a plus sign from the last two paths
            // FIXME: = sign will also have two paths.
            print("multiple paths!")
            
            if isPlusSign(paths: Array(recentPaths.suffix(2))) {
                return .emitter
            }
            if isEqualsSign(paths: Array(recentPaths.suffix(2))) {
                return .cymbal
            }
        }
        
        for path in recentPaths {
            let recognizer = RecognizablePath(path: path)
            if let type = recognizer.recognizedType {
                return type
            }
        }
        
        // Then try multi-path recognition
        return nil
    }
    
    // Check if two paths form a plus sign
    private func isPlusSign(paths: [UIBezierPath]) -> Bool {
        guard paths.count >= 2 else { return false }
        
        // Extract path elements for analysis
        let elements1 = paths[0].cgPath.getPathElements()
        let elements2 = paths[1].cgPath.getPathElements()
        
        // Basic length checks
        guard elements1.count > 3, elements2.count > 3 else { return false }
        
        // Calculate bounding boxes
        let bounds1 = paths[0].bounds
        let bounds2 = paths[1].bounds
        
        // Check if paths intersect
        guard bounds1.intersects(bounds2) else { return false }
        
        // Analyze the orientation of each path
        let orientation1 = getPathOrientation(elements: elements1)
        let orientation2 = getPathOrientation(elements: elements2)
        
        // For a plus sign, paths should be roughly perpendicular
        let isPerpendicularPaths = isApproximatelyPerpendicular(orientation1, orientation2)
        
        // Check if paths cross near their centers
        let center1 = CGPoint(x: bounds1.midX, y: bounds1.midY)
        let center2 = CGPoint(x: bounds2.midX, y: bounds2.midY)
        let centersClose = distance(center1, center2) < max(bounds1.width, bounds1.height, bounds2.width, bounds2.height) * 0.5
        
        return isPerpendicularPaths && centersClose
    }
    
    // Check if two paths form an equals sign (=)
    private func isEqualsSign(paths: [UIBezierPath]) -> Bool {
        guard paths.count >= 2 else { return false }
        
        // Extract path elements for analysis
        let elements1 = paths[0].cgPath.getPathElements()
        let elements2 = paths[1].cgPath.getPathElements()
        
        // Basic length checks
        guard elements1.count > 3, elements2.count > 3 else { return false }
        
        // Calculate bounding boxes
        let bounds1 = paths[0].bounds
        let bounds2 = paths[1].bounds
        
        // Both lines should be primarily horizontal
        let isHorizontal1 = bounds1.width > bounds1.height * 1.5
        let isHorizontal2 = bounds2.width > bounds2.height * 1.5
        guard isHorizontal1 && isHorizontal2 else { return false }
        
        // Analyze the orientation of each path
        let orientation1 = getPathOrientation(elements: elements1)
        let orientation2 = getPathOrientation(elements: elements2)
        print("path orientation: \(orientation1), \(orientation2)")
        
        // For equals sign, paths should be roughly parallel
        let isParallelPaths = isApproximatelyParallel(orientation1, orientation2)
        
        // They should be vertically stacked with some gap
//        let verticalSeparation = abs(bounds1.midY - bounds2.midY)
//        let averageHeight = (bounds1.height + bounds2.height) / 2
//        let isCorrectlySpaced = verticalSeparation > averageHeight * 0.5 && verticalSeparation < averageHeight * 3
        let isCorrectlySpaced = true
        
        // They should be roughly the same length and roughly aligned horizontally
        let widthRatio = max(bounds1.width, bounds2.width) / min(bounds1.width, bounds2.width)
        let isHorizontallyAligned = abs(bounds1.midX - bounds2.midX) < max(bounds1.width, bounds2.width) * 0.3
        let isSimilarLength = widthRatio < 1.5
        
        print("parallel: \(isParallelPaths), spaced: \(isCorrectlySpaced), aligned: \(isHorizontallyAligned), length: \(isSimilarLength)")
        
        return isParallelPaths && isCorrectlySpaced && isHorizontallyAligned && isSimilarLength
    }
    
    // Check if two orientations are approximately parallel
    private func isApproximatelyParallel(_ angle1: CGFloat, _ angle2: CGFloat) -> Bool {
        let angleDiff = abs(normalizeAngle(angle1 - angle2))
        let parallelAngleDiff: CGFloat = 0  // 0 degrees or 180 degrees (pi)
        let tolerance: CGFloat = .pi / 6  // 30 degrees tolerance
        
        return angleDiff < tolerance || abs(angleDiff - .pi) < tolerance
    }
    
    // Calculate dominant orientation (horizontal vs vertical)
    private func getPathOrientation(elements: [CGPath.PathElement]) -> CGFloat {
        guard elements.count > 1 else { return 0 }
        
        // Get first and last points to determine overall direction
        let firstPoint = elements.first!.point
        let lastPoint = elements.last!.point
        
        let dx = lastPoint.x - firstPoint.x
        let dy = lastPoint.y - firstPoint.y
        
        // Return angle in radians
        return atan2(dy, dx)
    }
    
    // Check if two orientations are approximately perpendicular
    private func isApproximatelyPerpendicular(_ angle1: CGFloat, _ angle2: CGFloat) -> Bool {
        let angleDiff = abs(normalizeAngle(angle1 - angle2))
        let perpendicularAngle: CGFloat = .pi / 2  // 90 degrees
        let tolerance: CGFloat = .pi / 6  // 30 degrees tolerance
        
        return abs(angleDiff - perpendicularAngle) < tolerance
    }
    
    // Normalize angle to [-π, π]
    private func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        var result = angle
        while result > .pi {
            result -= 2 * .pi
        }
        while result < -.pi {
            result += 2 * .pi
        }
        return result
    }
    
    // Calculate distance between two points
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // Clear all stored paths
    func clearPaths() {
        recentPaths.removeAll()
    }
    
    // Call this when the view is about to disappear or when cleaning up
    func cleanup() {
        cancelRecognitionTimer()
        clearPaths()
    }
}

// Original single path recognition logic
struct RecognizablePath {
    let path: UIBezierPath
    var recognizedType: ItemType? {
        if recognizePlusSign() {
            return .emitter
        } else if recognizeDrum() {
            return .drum
        } else if recognizeCircle() {
            return .blackhole
        } else if recognizeTriangle() {
            return .splitter
        } else if recognizeHorizontalLine() {
            return .note
        } else if recognizeSpring() {
            return .spring
        } else if recognizeCymbal() {
            return .cymbal
        }
        return nil
    }
    
    // Original plus sign recognition (kept for single-stroke attempts)
    private func recognizePlusSign() -> Bool {
//        let elements = path.cgPath.getPathElements()
//        guard elements.count > 10 else { return false } // Too short to be a +
//        
//        let directionAnalysis = analyzeDirections(elements: elements)
//        return hasCrossPattern(directions: directionAnalysis)
        
        // we're returning false here for now as the analysis on the two stroke version works well
        return false
    }
    
    // MARK: - Spring Recognition ('S' shape)
    private func recognizeSpring() -> Bool {
        // FIXME: this doesn't work at all as it currently is
        let elements = path.cgPath.getPathElements()
        guard elements.count > 10 else { return false } // Too short for an S
        
        let directionAnalysis = analyzeDirections(elements: elements)
        
        // S shape typically has 2-3 major direction reversals
        guard directionAnalysis.directionChanges >= 2 else { return false }
        
        // Look for direction changes that reverse roughly 180 degrees
        let reversalTolerance = CGFloat.pi / 4 // ±45°
        let reversals = directionAnalysis.dominantAngles.filter {
            abs(abs($0) - .pi) < reversalTolerance
        }
        
        // S shape should have vertical predominance
        let bounds = path.bounds
        let isVerticallyOriented = bounds.height > bounds.width
        
        return reversals.count >= 2 && isVerticallyOriented
    }
    
    // MARK: - Drum Recognition ('U' shape)
    private func recognizeDrum() -> Bool {
        // FIXME: this doesn't seem to work at all either.
        let elements = path.cgPath.getPathElements()
        guard elements.count > 5 else { return false }
        
        // U shape should have a specific width-to-height ratio
        let bounds = path.bounds
        let aspectRatio = bounds.width / bounds.height
        guard aspectRatio < 1.5 && aspectRatio > 0.5 else { return false }
        
        let directionAnalysis = analyzeDirections(elements: elements)
        
        // Look for a pattern with 2 major turns (the bottom corners of the U)
        guard directionAnalysis.directionChanges >= 2 else { return false }
        
        // Check for approximately 90° turns
        let rightAngleTolerance = CGFloat.pi / 6 // ±30°
        let rightAngles = directionAnalysis.dominantAngles.filter {
            abs(abs($0) - .pi/2) < rightAngleTolerance
        }
        
        // Check if the path is open at the top
        let firstPoint = elements.first!.point
        let lastPoint = elements.last!.point
        let horizontalDistance = abs(firstPoint.x - lastPoint.x)
        let verticalDistance = abs(firstPoint.y - lastPoint.y)
        let openAtTop = horizontalDistance > bounds.width * 0.5 && verticalDistance < bounds.height * 0.3
        
        return rightAngles.count >= 2 && openAtTop
    }
    
    // MARK: - Cymbal Recognition ('=' shape)
    private func recognizeCymbal() -> Bool {
        let elements = path.cgPath.getPathElements()
        guard elements.count > 5 else { return false }
        
        // Equal sign should be wider than tall
        let bounds = path.bounds
        let aspectRatio = bounds.width / bounds.height
        guard aspectRatio > 1.5 else { return false }
        
        // For a drawn equal sign, we'd expect 3 major segments (for two parallel lines)
        // with 2 pen lifts or direction changes
        let directionAnalysis = analyzeDirections(elements: elements)
        
        // Equal sign should have horizontal predominance
        let isHorizontallyOriented = bounds.width > bounds.height
        
        return directionAnalysis.directionChanges >= 1 && isHorizontallyOriented
    }
    
    // MARK: - Direction Analysis
    
    private struct DirectionAnalysis {
        let directionChanges: Int
        let dominantAngles: [CGFloat] // In radians
    }
    
    private func analyzeDirections(elements: [CGPath.PathElement]) -> DirectionAnalysis {
        var directionChanges = 0
        var angleSamples = [CGFloat]()
        var previousDirection: CGVector?
        
        for i in 1..<elements.count {
            let currentDirection = CGVector(from: elements[i-1].point, to: elements[i].point)
            
            if let prev = previousDirection, !currentDirection.isSimilar(to: prev) {
                directionChanges += 1
                angleSamples.append(prev.angle(to: currentDirection))
            }
            previousDirection = currentDirection
        }
        
        return DirectionAnalysis(
            directionChanges: directionChanges,
            dominantAngles: angleSamples
        )
    }
    
    // MARK: - Cross Pattern Detection
    
    private func hasCrossPattern(directions: DirectionAnalysis) -> Bool {
        // 1. Check for sufficient direction changes (4+ for +)
        guard directions.directionChanges >= 4 else { return false }
        
        // 2. Check for approximately 90° angle changes
        let ninetyDegreeTolerance = CGFloat.pi / 6 // ±30°
        let rightAngleSamples = directions.dominantAngles.filter {
            abs(abs($0) - .pi/2) < ninetyDegreeTolerance
        }
        
        // 3. Require at least 2 near-90° turns
        return rightAngleSamples.count >= 2
    }
    
    // MARK: - Circle Recognition
    
    private func recognizeCircle() -> Bool {
        // Simplified circle detection
        let bounds = path.bounds
        let width = bounds.width
        let height = bounds.height
        
        // Circle should be relatively square
        let aspectRatio = max(width, height) / min(width, height)
        guard aspectRatio < 1.3 else { return false }
        
        // Calculate approximate perimeter based on bounds
        let approximatePerimeter = .pi * (width + height) / 2
        
        // Calculate actual path length
        let pathLength = calculatePathLength()
        
        // The ratio of actual length to expected circle perimeter should be close to 1
        let perimeterRatio = pathLength / approximatePerimeter
        
        // FIXME: Check if the path closes on itself
        // let elements = path.cgPath.getPathElements()
        // let isClosed = distance(elements.first!.point, elements.last!.point) < min(width, height) * 0.25
        let isClosed = true
        
        return perimeterRatio > 0.7 && perimeterRatio < 1.3 && isClosed
    }
    
    // MARK: - Triangle Recognition
    
    private func recognizeTriangle() -> Bool {
        let elements = path.cgPath.getPathElements()
        guard elements.count > 6 else { return false } // Too short to be a triangle
        
        let directionAnalysis = analyzeDirections(elements: elements)
        
        // Triangle should have 3 significant direction changes (corners)
        guard directionAnalysis.directionChanges >= 2 else { return false }
        
        // Look for sharp angle changes typical in triangles (approximately 60-120 degrees)
        let triangleAngleTolerance = CGFloat.pi / 3 // ±60°
        let sharpTurns = directionAnalysis.dominantAngles.filter {
            $0.magnitude > triangleAngleTolerance
        }
        
        // Check if the path closes on itself
        let isClosed = distance(elements.first!.point, elements.last!.point) < path.bounds.width * 0.25
        
        return sharpTurns.count >= 2 && isClosed
    }
    
    // MARK: - Horizontal Line Recognition
    
    private func recognizeHorizontalLine() -> Bool {
        let elements = path.cgPath.getPathElements()
        guard elements.count > 3 else { return false }
        
        let bounds = path.bounds
        
        // Line should be much wider than tall
        let aspectRatio = bounds.width / bounds.height
        guard aspectRatio > 3.0 else { return false }
        
        // Line should be relatively straight (few direction changes)
        let directionAnalysis = analyzeDirections(elements: elements)
        return directionAnalysis.directionChanges < 3
    }
    
    // Helper methods
    
    private func calculatePathLength() -> CGFloat {
        let elements = path.cgPath.getPathElements()
        guard elements.count > 1 else { return 0 }
        
        var length: CGFloat = 0
        for i in 1..<elements.count {
            length += distance(elements[i-1].point, elements[i].point)
        }
        return length
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
}

// Existing Extensions
extension CGVector {
    init(from p1: CGPoint, to p2: CGPoint) {
        self.init(dx: p2.x - p1.x, dy: p2.y - p1.y)
    }
    
    func angle(to other: CGVector) -> CGFloat {
        let dot = dx * other.dx + dy * other.dy
        let det = dx * other.dy - dy * other.dx
        return atan2(det, dot)
    }
    
    func isSimilar(to other: CGVector, tolerance: CGFloat = 0.3) -> Bool {
        return angle(to: other).magnitude < tolerance
    }
}

extension CGFloat {
    var magnitude: CGFloat {
        return abs(self)
    }
}

extension CGPath {
    struct PathElement {
        let type: CGPathElementType
        let point: CGPoint
    }
    
    func getPathElements() -> [PathElement] {
        var elements = [PathElement]()
        forEach { elements.append(PathElement(type: $0.type, point: $0.points.pointee)) }
        return elements
    }
    
    func forEach(body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { info, element in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
}

extension CGFloat {
    func radiansToDegrees() -> CGFloat {
        return self * 180 / .pi
    }
}
