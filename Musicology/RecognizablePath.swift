//
//  RecognizablePath.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//

import UIKit

// Add this at the top of the file (or create a separate ItemType.swift)
enum ItemType: String {
    case emitter    // +
    case spring     // s
    case blackhole  // o
    case splitter   // triangle
    case drum       // U
    case cymbal     // =
    case note       // -
}

struct RecognizablePath {
    let path: UIBezierPath
    var recognizedType: ItemType? = nil
    
    init(path: UIBezierPath) {
        self.path = path
        self.recognizedType = recognizeShape()
    }
    
    private func recognizeShape() -> ItemType? {
        let simplified = simplifyPath(path)
        
        // Basic recognition logic (expand these)
        if looksLikePlus(simplified) { return .emitter }
        //if looksLikeLetterS(simplified) { return .spring }
        //if looksLikeCircle(simplified) { return .blackhole }
        
        return nil
    }
    
    // Add these helper methods:
    private func simplifyPath(_ path: UIBezierPath) -> UIBezierPath {
        let simplifiedPath = UIBezierPath()
                // Get path points (approximation)
                let pathElements = path.cgPath.getPathElements()
                guard !pathElements.isEmpty else { return path }
                
                // Simple simplification: take every 3rd point
                for (index, element) in pathElements.enumerated() {
                    if index % 3 == 0 {
                        if index == 0 {
                            simplifiedPath.move(to: element.point)
                        } else {
                            simplifiedPath.addLine(to: element.point)
                        }
                    }
                }
                return simplifiedPath
            }
    
    private func looksLikePlus(_ path: UIBezierPath) -> Bool {
        // Analyze points to detect + shape
        return false // placeholder
    }
    
    // Add similar methods for other shapes...
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

// MARK: - Vector Math Helper
extension CGVector {
    init(from p1: CGPoint, to p2: CGPoint) {
        self.init(dx: p2.x - p1.x, dy: p2.y - p1.y)
    }
    
    func isSimilar(to other: CGVector, angleTolerance: CGFloat = 0.3) -> Bool {
        let dotProduct = dx * other.dx + dy * other.dy
        let magnitude = sqrt(dx * dx + dy * dy) * sqrt(other.dx * other.dx + other.dy * other.dy)
        guard magnitude > 0 else { return false }
        let cosine = dotProduct / magnitude
        return abs(cosine) > cos(angleTolerance)
    }
}
