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
    //private var animationTimers: [CADisplayLink] = []
    private var collisionManager:  CollisionManager?
    private var gameUpdateTimer : CADisplayLink?
    private var isGameActive = true
    private var soundEngine: SoundEngine?
    weak var editPanelVC: EditPanelViewController?
    private var emitterPhysicsMap: [ObjectIdentifier: EmitterPhysics] = [:]

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Game Board", color: .systemRed)
        setupDrawingView()
        setupShapeRecognition()
        startCollisionManager()
        startGameLoop()
        startSoundEngine()
        
    }
    
    private func startGameLoop() {
        // Stop any existing timer
        gameUpdateTimer?.invalidate()
        
        // Create new timer
        gameUpdateTimer = CADisplayLink(target: self, selector: #selector(gameUpdate))
        gameUpdateTimer?.preferredFramesPerSecond = 60
        gameUpdateTimer?.add(to: .main, forMode: .common)
    }
    
    @objc private func gameUpdate(_ timer: CADisplayLink) {
        // Always process active balls, even when emitters are paused
        updateBalls()
        checkCollisions()
        cleanupExpiredBalls()
    }
    
    private func updateBalls() {
        for ball in activeBalls {
            ball.updatePosition()
        }
    }
    
    private func checkCollisions() {
        // Check object collisions
        if !activeBalls.isEmpty {
            let collisionObjects = gameItems.compactMap { $0 as? CollisionObject }
            collisionManager?.checkCollisions(balls: activeBalls, objects: collisionObjects)
        }
    }
    
    private func cleanupExpiredBalls() {
        activeBalls.removeAll { ball in
            if ball.lifetime <= 0 || isOutOfBounds(ball) {
                ball.removeFromSuperview()
                return true
            }
            return false
        }
    }
    
    private func isOutOfBounds(_ ball: BallView) -> Bool {
        let radius = ball.bounds.width / 2
        let screenBounds = view.bounds
        
        return ball.center.x - radius <= screenBounds.minX ||
               ball.center.x + radius >= screenBounds.maxX ||
               ball.center.y - radius <= screenBounds.minY ||
               ball.center.y + radius >= screenBounds.maxY
    }
    
    private func startCollisionManager() {
        collisionManager = CollisionManager()
    }
    
    private func startSoundEngine() {
        soundEngine = SoundEngine()
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
            // let centerPosition = self.view.center
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
        newItem.delegate = self
        
        gameItems.append(newItem)
    }
    
    private func handleRecognizedItem(_ type: ItemType) {
        print("item is: \(type)")
        let centerPoint = view.convert(view.center, from: view.superview)
        placeItem(type: type, at: centerPoint)
    }
}

//extension GameBoardViewController: ShapeRecognizerDelegate {
//    func didRecognizeShape(_ type: ItemType, at position: CGPoint) {
//        // Convert position if needed
//        print("recognizing shape")
//        let convertedPosition = view.convert(position, from: drawingView)
//        
//        // Visual feedback
//        showRecognitionFeedback(for: type, at: convertedPosition)
//        
//        // Create the item after a slight delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            self.placeItem(type: type, at: convertedPosition)
//        }
//    }
//    
//    private func showRecognitionFeedback(for type: ItemType, at position: CGPoint) {
//        let feedbackView = UIImageView(image: UIImage(named: type.imageName))
//        feedbackView.center = position
//        feedbackView.alpha = 0
//        feedbackView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
//        view.addSubview(feedbackView)
//        
//        UIView.animate(withDuration: 0.2, animations: {
//            feedbackView.alpha = 1
//            feedbackView.transform = .identity
//        }) { _ in
//            UIView.animate(withDuration: 0.2, delay: 0.5, options: [], animations: {
//                feedbackView.alpha = 0
//            }) { _ in
//                feedbackView.removeFromSuperview()
//            }
//        }
//    }
//}

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
            // there may be some issue here:
//            physics.startEmitting { [weak self, weak emitterItem] direction, pipeIndex in
//                        guard let strongSelf = self, let strongEmitterItem = emitterItem else { return }
//                        strongSelf.createBall(from: strongEmitterItem, direction: direction, pipeIndex: pipeIndex)
//                    }
            physics.startEmitting { [weak self] direction, pipeIndex in
                self?.createBall(from: emitter, direction: direction, pipeIndex: pipeIndex)
            }
            activeEmitters.append(physics)
            emitterPhysicsMap[ObjectIdentifier(emitter)] = physics
        }
    }
    
    private func stopEmitters() {
        // Stop and clear all active emitters
        activeEmitters.forEach { $0.stopEmitting() }
        activeEmitters.removeAll()
        emitterPhysicsMap.removeAll()
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
    }
}

extension GameBoardViewController: GameItemDelegate {
    func gameItemDidUpdate(_ item: any GameItem) {
        if let emitterItem = item as? EmitterItem {
            if let physicsInstance = emitterPhysicsMap[ObjectIdentifier(emitterItem)] {
                // Get the LATEST config directly from the EmitterItem that was updated
                guard let currentItemConfig = emitterItem.audioConfiguration as? EmitterConfiguration else {
                     print("❌ Could not cast emitterItem.audioConfiguration to EmitterConfiguration in gameItemDidUpdate")
                     return
                }
                print("✅ Updating EmitterPhysics from gameItemDidUpdate for item. BPM: \(currentItemConfig.bpm), Staggered: \(currentItemConfig.isStaggered)")
                physicsInstance.updateConfig(currentItemConfig)
            } else {
                // This is normal if the game is stopped or the specific emitter isn't active.
                 print("ℹ️ gameItemDidUpdate for EmitterItem, but no active physics instance in map. Item: \(emitterItem.type) at \(emitterItem.frame.origin)")
            }
        }
            // Handle other game item types if necessary
//        if let emitter = item as? EmitterItem,
//           let index = gameItems.firstIndex(where: { $0 === item }),
//           index < activeEmitters.count {
//            
//            activeEmitters[index].updateConfig(emitter.audioConfiguration as! EmitterConfiguration)
//        }
    }
    
    func gameItemDidCollide(_ item: GameItem) {
        print("play sound now \(item.type)")
        switch item.type {
            case ItemType.drum:
                soundEngine?.playSnare()
                break
            case ItemType.cymbal:
                soundEngine?.playCymbal()
                break
            case ItemType.note:
                soundEngine?.playNote()
                break
            case ItemType.blackhole:
                soundEngine?.playKick()
                break
            default:
                break
        }
    }
    
    func gameItemWasSelected(_ item: GameItem) {
        // Show edit panel with this item's configuration
        print("showing edit panel for \(item.type)")
        editPanelVC?.configure(for: item)
    }
    
    
}

extension GameBoardViewController: EditPanelDelegate {
    func editPanelDidRequestTestSound(_ panel: EditPanelViewController, item: any GameItem) {
        if let draggableItem = item as? DraggableGameItem {
            draggableItem.playTestSound()
        }
    }
    
    func editPanel(_ panel: EditPanelViewController,
                       didUpdateConfiguration configuration: AudioConfiguration,
                       for item: GameItem) {
            // Update the item's configuration
            if let draggableItem = item as? DraggableGameItem {
                draggableItem.updateAudioConfiguration(configuration)
            }
            
            // Forward to type-specific handlers
            switch configuration {
            case let emitterConfig as EmitterConfiguration:
                editPanel(panel, didUpdateEmitterConfiguration: emitterConfig, for: item)
            case let drumConfig as DrumConfiguration:
                editPanel(panel, didUpdateDrumConfiguration: drumConfig, for: item)
            default:
                break
            }
        }
    
    // Emitter-specific updates
        func editPanel(_ panel: EditPanelViewController,
                       didUpdateEmitterConfiguration config: EmitterConfiguration,
                       for item: GameItem) {
            guard let emitterItem = item as? EmitterItem else {
                print("❌ Item is not an EmitterItem in didUpdateEmitterConfiguration")
                return
            }
            
            if let physicsInstance = emitterPhysicsMap[ObjectIdentifier(emitterItem)] {
                print("✅ Updating EmitterPhysics for item via map. New BPM: \(config.bpm), Staggered: \(config.isStaggered)")
                physicsInstance.updateConfig(config)
            } else {
                print("⚠️ Could not find active EmitterPhysics for item: \(emitterItem) in map to update config.")
                // This might happen if the item was edited while emitters were globally stopped.
            }
            
//            guard let emitterIndex = gameItems.firstIndex(where: { $0 === item }),
//                  activeEmitters.indices.contains(emitterIndex) else { return }
//            
//            activeEmitters[emitterIndex].updateConfig(config)
        }
        
        // Drum-specific updates
        func editPanel(_ panel: EditPanelViewController,
                       didUpdateDrumConfiguration config: DrumConfiguration,
                       for item: GameItem) {
            // Handle drum-specific live updates
//            if let drum = item as? DrumItem {
//                drum.applyConfiguration(config)
//            }
        }
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
