//
//  GameBoardViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class GameBoardViewController: UIViewController, LabelProviding {
    private let drawingView = DrawingView()
    private var gameItems = [GameItem]()
    private var activeEmitters: [EmitterPhysics] = []
    private var activeBalls = [BallView]()
    private var animationTimers: [CADisplayLink] = []

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Game Board", color: .systemRed)
        setupDrawingView()
        setupShapeRecognition()
        //startCollisionTimer()
        
    }
    
    private func setupDrawingView() {
        drawingView.backgroundColor = .clear
        drawingView.isOpaque = false
        
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawingView)
        
        NSLayoutConstraint.activate([
            drawingView.topAnchor.constraint(equalTo: view.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            drawingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupShapeRecognition() {
        drawingView.shapeRecognizer.onShapeRecognized = { [weak self] itemType in
            guard let self = self, let itemType = itemType else {
                print("No shape recognized or self is nil")
                return
            }
            
            // Use the center of the view for now
            let centerPosition = self.view.center
            self.handleRecognizedItem(itemType)
            
            self.drawingView.clearCanvas()
        }
    }
    
    func placeItem(type: ItemType, at position: CGPoint) {
        let itemSize = CGSize(width: 60, height: 60)
        let frame = CGRect(origin: position, size: itemSize)
        
        let newItem: DraggableGameItem
        
        switch type {
            case .emitter:
                newItem = EmitterItem(type: type, frame: frame)
            default:
                newItem = DraggableGameItem(type: type, frame: frame)
            }
        
        newItem.center = position
        view.addSubview(newItem)
        
        gameItems.append(newItem)
    }
    
    private func handleRecognizedItem(_ type: ItemType) {
        print("item is: \(type)")
        let centerPoint = view.convert(view.center, from: view.superview)
        placeItem(type: type, at: centerPoint)
    }
    
//    private func startCollisionTimer() {
//        let displayLink = CADisplayLink(target: self, selector: #selector(checkCollisions))
//        displayLink.add(to: .main, forMode: .common)
//    }
//
//    @objc private func checkCollisions() {
//        // this is being called but the if statement is never true, we might want to just get rid of it.
//        // it wasn't being called due to balls bounding off objects, now that balls don't bounce it is being caclled multiple times.
//        for ball in activeBalls {
//            for item in gameItems {
//                if ball.canCollideWith(item as! UIView) && ball.frame.intersects(item.view.frame) {
//                    handleCollision(ball: ball, with: item)
//                }
//            }
//        }
//    }
//
//    private func handleCollision(ball: BallView, with item: GameItem) {
//        print("collision with from gb: \(item.type)")
//        // 1. Trigger sound based on item type
//        //triggerSound(for: item)
//        
//        // 2. Visual feedback
//        //animateImpact(on: item.view)
//        
//        // 3. Physics response
//        //handlePhysics(ball: ball, item: item)
//    }
    
}

extension GameBoardViewController: ShapeRecognizerDelegate {
    func didRecognizeShape(_ type: ItemType, at position: CGPoint) {
        // Convert position if needed
        let convertedPosition = view.convert(position, from: drawingView)
        
        // Visual feedback
        showRecognitionFeedback(for: type, at: convertedPosition)
        
        // Create the item after a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.placeItem(type: type, at: convertedPosition)
        }
    }
    
    private func showRecognitionFeedback(for type: ItemType, at position: CGPoint) {
        let feedbackView = UIImageView(image: UIImage(named: type.imageName))
        feedbackView.center = position
        feedbackView.alpha = 0
        feedbackView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        view.addSubview(feedbackView)
        
        UIView.animate(withDuration: 0.2, animations: {
            feedbackView.alpha = 1
            feedbackView.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5, options: [], animations: {
                feedbackView.alpha = 0
            }) { _ in
                feedbackView.removeFromSuperview()
            }
        }
    }
}

extension GameBoardViewController: PlayControlDelegate {
    func playStateChanged(isPlaying: Bool) {
        if isPlaying {
            startEmitters()
        } else {
            stopEmitters()
        }
    }
    
    private func startEmitters() {
        // Clear any existing active emitters first
        stopEmitters()
        
        // Find all emitter items and start them
        let emitters = gameItems.compactMap { $0 as? EmitterItem }
        emitters.forEach { emitter in
            let config = EmitterConfiguration(
                bpm: Double(emitter.bpm),
                velocity: CGFloat(emitter.velocity),
                isStaggered: emitter.isStaggered
            )
            
            let physics = EmitterPhysics(config: config)
            physics.startEmitting { [weak self] direction, pipeIndex in
                self?.createBall(from: emitter, direction: direction, pipeIndex: pipeIndex)
            }
            activeEmitters.append(physics)
        }
    }
    
    private func stopEmitters() {
        // Stop and clear all active emitters
        activeEmitters.forEach { $0.stopEmitting() }
        activeEmitters.removeAll()
    }
    
    private func createBall(from emitter: DraggableGameItem,
                           direction: CGVector,
                           pipeIndex: Int) {
        let ball = BallView()
        let emitterFrame = emitter.frame // Updated to access frame directly
        
        // Position balls at the ends of each emitter "pipe"
        let offset: CGFloat = 40
        var startPoint = CGPoint(x: emitterFrame.midX, y: emitterFrame.midY)
        
        switch pipeIndex {
        case 0: startPoint.y -= offset // Up
        case 1: startPoint.x += offset // Right
        case 2: startPoint.y += offset // Down
        case 3: startPoint.x -= offset // Left
        default: break
        }
        
        ball.center = startPoint
        view.insertSubview(ball, belowSubview: emitter) // Updated to use emitter directly
        
        animateBall(ball, direction: direction)
        activeBalls.append(ball)
    }
    
    private func animateBall(_ ball: BallView, direction: CGVector) {
        ball.velocity = direction * 2.0 // Scale factor
            
        let animationTimer = CADisplayLink(target: self, selector: #selector(updateBallPosition))
        animationTimer.preferredFramesPerSecond = 60
        animationTimer.add(to: .main, forMode: .common)
        
        // Store the ball reference in the timer object using associated objects
        objc_setAssociatedObject(animationTimer, &AssociatedKeys.ballKey, ball, .OBJC_ASSOCIATION_RETAIN)
        
        // Keep the timer in an array so it doesn't get deallocated
        animationTimers.append(animationTimer)
        
        //ball.tag = animationDates // Store reference
        
//        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveLinear]) {
//            ball.center.x += direction.dx * 500
//            ball.center.y += direction.dy * 500
//        } completion: { _ in
//            ball.removeFromSuperview()
//        }
    }
    
    @objc private func updateBallPosition(_ timer: CADisplayLink) {
        // Get the associated ball for this timer
        guard let ball = objc_getAssociatedObject(timer, &AssociatedKeys.ballKey) as? BallView else {
            return
        }
        
        // Update position based on velocity
        ball.updatePosition()
        
        // Check for collisions with screen boundaries
        checkBoundaryCollisions(for: ball, timer: timer)
        
        // Check for collisions with other objects
        checkObjectCollisions(for: ball, timer: timer)
        
        // Remove the ball if it has no more lifetime
        if ball.lifetime <= 0 {
            removeBall(ball, timer: timer)
        }
    }
    
    private func checkBoundaryCollisions(for ball: BallView, timer: CADisplayLink) {
        let radius = ball.bounds.width / 2
        let screenBounds = view.bounds
        
        // Check if ball hits any boundary
            if ball.center.x - radius <= screenBounds.minX ||
               ball.center.x + radius >= screenBounds.maxX ||
               ball.center.y - radius <= screenBounds.minY ||
               ball.center.y + radius >= screenBounds.maxY {
                // Remove the ball instead of bouncing
                removeBall(ball, timer: timer)
            }
        
//        // Left and right boundaries
//        if ball.center.x - radius <= screenBounds.minX {
//            ball.center.x = screenBounds.minX + radius
//            ball.velocity.dx = -ball.velocity.dx * 0.8 // Bounce with some energy loss
//            ball.lifetime -= 1
//        } else if ball.center.x + radius >= screenBounds.maxX {
//            ball.center.x = screenBounds.maxX - radius
//            ball.velocity.dx = -ball.velocity.dx * 0.8
//            ball.lifetime -= 1
//        }
//        
//        // Top and bottom boundaries
//        if ball.center.y - radius <= screenBounds.minY {
//            ball.center.y = screenBounds.minY + radius
//            ball.velocity.dy = -ball.velocity.dy * 0.8
//            ball.lifetime -= 1
//        } else if ball.center.y + radius >= screenBounds.maxY {
//            ball.center.y = screenBounds.maxY - radius
//            ball.velocity.dy = -ball.velocity.dy * 0.8
//            ball.lifetime -= 1
//        }
    }
    
    private func checkObjectCollisions(for ball: BallView, timer: CADisplayLink) {
        // Example: Check collisions with specific game objects
        // This could be extended to check collisions with any UIView subclass
        let currentTime = CACurrentMediaTime()
        
        for subview in view.subviews {
            // Skip the ball itself and other non-collidable objects
            if subview == ball || !(subview is CollisionObject) {
                continue
            }
            
            if ball.canCollideWith(subview) &&
               checkCollision(between: ball, and: subview) {
                
                handleCollision(between: ball, and: subview)
                ball.registerCollision(with: subview, at: currentTime)
                
                // Log collision for debugging
                if let collisionObject = subview as? CollisionObject,
                   let name = collisionObject.name {
                    print("collision with COC: \(name)")
                }
            }
        }
    }
    
    private func checkCollision(between ball: BallView, and object: UIView) -> Bool {
        // Simple rectangular collision detection
        return ball.frame.intersects(object.frame)
    }
    
    private func handleCollision(between ball: BallView, and object: UIView) {
        // Simple bounce logic - determine which side was hit
//        let ballCenter = ball.center
//        let objectCenter = object.center
//        
//        let dx = ballCenter.x - objectCenter.x
//        let dy = ballCenter.y - objectCenter.y
//        
//        // Simplified collision response
//        if abs(dx) > abs(dy) {
//            // Horizontal collision
//            ball.velocity.dx = -ball.velocity.dx * 0.8
//            
//            // Position adjustment to prevent sticking
//            if dx > 0 {
//                ball.center.x = object.frame.maxX + ball.bounds.width / 2
//            } else {
//                ball.center.x = object.frame.minX - ball.bounds.width / 2
//            }
//        } else {
//            // Vertical collision
//            ball.velocity.dy = -ball.velocity.dy * 0.8
//            
//            // Position adjustment to prevent sticking
//            if dy > 0 {
//                ball.center.y = object.frame.maxY + ball.bounds.height / 2
//            } else {
//                ball.center.y = object.frame.minY - ball.bounds.height / 2
//            }
//        }
        
        ball.lifetime -= 1
        
        // Notify the collision object if it implements a collision handler
        if let collisionObject = object as? CollisionObject {
            collisionObject.handleCollision(with: ball)
        }
    }
    
    private func removeBall(_ ball: BallView, timer: CADisplayLink) {
        // Remove the ball from the view and active balls list
        ball.removeFromSuperview()
        if let index = activeBalls.firstIndex(of: ball) {
            activeBalls.remove(at: index)
        }
        
        // Stop and remove the timer
        timer.invalidate()
        if let timerIndex = animationTimers.firstIndex(of: timer) {
            animationTimers.remove(at: timerIndex)
        }
    }
}

// Protocol for objects that can collide with balls
protocol CollisionObject {
    var name: String? { get }
    func handleCollision(with ball: BallView)
}

// Associated objects key for storing ball reference in the CADisplayLink
private struct AssociatedKeys {
    static var ballKey = "BallKey"
}

// Operator overload for vector multiplication
extension CGVector {
    static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
        return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }
}
