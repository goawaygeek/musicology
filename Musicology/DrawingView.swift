//
//  DrawingView.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class DrawingView: UIView {
    // Track drawing state
    private var currentPath: UIBezierPath?
    private var paths = [UIBezierPath]()
    
    // Shape recognizer with timer functionality
    let shapeRecognizer = ShapeRecognizer()
    
    // Configure drawing appearance
    var strokeColor: UIColor = .label {
        didSet { setNeedsDisplay() }
    }
    var strokeWidth: CGFloat = 3.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // Ensure proper drawing properties
        self.isOpaque = false
        self.backgroundColor = .clear
        self.contentMode = .redraw
        
        // Set up the shape recognizer callback -> we're calling the closure in GBVC now so this isn't necessary.
//        shapeRecognizer.onShapeRecognized = { [weak self] itemType in
//            guard let self = self else { return }
//            
//            if let itemType = itemType {
//                // Calculate the union of all paths' bounds to show feedback
//                var combinedBounds = CGRect.zero
//                for path in self.paths {
//                    if combinedBounds.isNull {
//                        combinedBounds = path.bounds
//                    } else {
//                        combinedBounds = combinedBounds.union(path.bounds)
//                    }
//                }
//                
//                // Show recognition feedback
//                self.showRecognitionFeedback(type: itemType, for: combinedBounds)
//            }
//            
//            // Clear the paths after recognition attempt (whether successful or not)
//            self.paths.removeAll()
//            self.setNeedsDisplay()
//        }
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.clear.setFill()
        UIRectFill(rect)
        
        strokeColor.setStroke()
        paths.forEach { $0.stroke() }
        currentPath?.stroke()
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Inform the recognizer that a new stroke is starting
        shapeRecognizer.beginPath()
        
        currentPath = UIBezierPath()
        currentPath?.lineWidth = strokeWidth
        currentPath?.lineCapStyle = .round
        currentPath?.lineJoinStyle = .round
        currentPath?.move(to: touch.location(in: self))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let path = currentPath else { return }
        path.addLine(to: touch.location(in: self))
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let path = currentPath else { return }
        
        // Add the completed path
        paths.append(path)
        
        // Add the path to the recognizer (this will start the recognition timer)
        shapeRecognizer.addPath(path)
        
        currentPath = nil
        setNeedsDisplay()
        logPathData(path) // For debugging
    }
    
    // MARK: - Debugging Helpers
    private func logPathData(_ path: UIBezierPath) {
        let pointCount = path.cgPath.getPathElements().count
        print("Path completed with \(pointCount) points")
        print("Bounds: \(path.bounds)")
    }
    
    func clearCanvas() {
        paths.removeAll()
        shapeRecognizer.clearPaths()
        setNeedsDisplay()
    }
    
    private func showRecognitionFeedback(type: ItemType, for bounds: CGRect) {
        // Create feedback view around the combined bounds of all paths
        let feedbackView = UIView(frame: bounds.insetBy(dx: -10, dy: -10))
        feedbackView.layer.cornerRadius = 8
        feedbackView.alpha = 0
        
        switch type {
        case .emitter:
            feedbackView.layer.borderColor = UIColor.systemGreen.cgColor
            feedbackView.layer.borderWidth = 3
        default:
            feedbackView.layer.borderColor = UIColor.systemBlue.cgColor
            feedbackView.layer.borderWidth = 2
        }
        
        addSubview(feedbackView)
        
        UIView.animate(withDuration: 0.3) {
            feedbackView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.0) {
                feedbackView.alpha = 0
            } completion: { _ in
                feedbackView.removeFromSuperview()
            }
        }
        
        print("Recognized: \(type.rawValue)")
    }
    
    // Clean up when the view is removed from hierarchy
    override func removeFromSuperview() {
        shapeRecognizer.cleanup()
        super.removeFromSuperview()
    }
    
    // Clean up when the view is about to be deallocated
    deinit {
        shapeRecognizer.cleanup()
    }
}
