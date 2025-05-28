//
//  DraggableGameItem.swift
//  Musicology
//
//  Created by Scott Brewer on 5/7/25.
//
import UIKit

class DraggableGameItem: BaseGameItemView, GameItem, CollisionObject {
    var id: UUID
    weak var delegate: GameItemDelegate?
    
    var collisionBounds: CGRect { return self.frame }
    
    var name: String?
    var position: CGPoint {
        get { return center }
        set { center = newValue }
    }
    
    var view: UIView { return self }
    
    var audioConfiguration: AudioConfiguration {
            didSet {
                // Optional: Update visual representation when config changes
                // updateVisualForConfiguration()
            }
        }
    
    private var tapGesture: UITapGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    
    override init(type: ItemType, frame: CGRect) {
        id = UUID()
        //collisionBounds = frame
        audioConfiguration = type.createDefaultAudioConfiguration()
        
        super.init(type: type, frame: frame)
        setupGestures()
        self.name = type.displayName
        // updateVisualForConfiguration()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGestures() {
        // Tap gesture for selection/editing
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tapGesture)
        
        // Pan gesture for dragging
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGesture.maximumNumberOfTouches = 1
        addGestureRecognizer(panGesture)
    }
    
    @objc private func didTap() {
        handleTap()
    }
    
    @objc private func didPan(_ gesture: UIPanGestureRecognizer) {
        handlePan(gesture)
    }
    
    func handleTap() {
        // Visual feedback
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        // for edit panel handling
        delegate?.gameItemWasSelected(self)
        
        // print("Selected \(type.displayName) for editing")
    }
    
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .began, .changed:
            center = CGPoint(x: center.x + translation.x,
                           y: center.y + translation.y)
            gesture.setTranslation(.zero, in: self)
            
        case .ended:
            // Snap to grid if needed
            // TODO: Implement your grid snapping logic
            break
            
        default:
            break
        }
    }
    
    func didCollide(with ball: BallView, at point: CGPoint) {
        delegate?.gameItemDidCollide(self)
        
        // Also trigger audio through the new system
        handleCollision()
    }
    
    func updateAudioConfiguration(_ newConfiguration: AudioConfiguration) {
        audioConfiguration = newConfiguration
        
        // Update the display name to reflect configuration
        updateDisplayName()
    }
    
    private func updateDisplayName() {
        switch audioConfiguration {
        case let drumConfig as DrumConfiguration:
            name = "\(drumConfig.drumType.displayName)"
        case let cymbalConfig as CymbalConfiguration:
            name = "\(cymbalConfig.cymbalType.displayName)"
        case let noteConfig as NoteConfiguration:
            name = "Note \(noteConfig.note)"
        default:
            name = type.displayName
        }
    }
    
    private func updateVisualForConfiguration() {
        // TODO: Add visual indicators based on configuration
        // i.e. change border color, etc.
        updateDisplayName()
        
        // Example: Add a subtle border color based on configuration type
        switch audioConfiguration {
        case is DrumConfiguration:
            layer.borderColor = UIColor.systemRed.cgColor
        case is CymbalConfiguration:
            layer.borderColor = UIColor.systemYellow.cgColor
        case is NoteConfiguration:
            layer.borderColor = UIColor.systemBlue.cgColor
        case is SilentConfiguration:
            layer.borderColor = UIColor.systemGray.cgColor
        default:
            layer.borderColor = UIColor.clear.cgColor
        }
        layer.borderWidth = audioConfiguration is SilentConfiguration ? 0 : 1.0
    }
    
    // Convenience methods for testing/debugging
    func playTestSound() {
        // Manually trigger the sound for testing
        handleCollision()
    }
    
    func getConfigurationDetails() -> [String: Any] {
        switch audioConfiguration {
        case let drumConfig as DrumConfiguration:
            return [
                "type": "drum",
                "drumType": drumConfig.drumType.rawValue,
                "volume": drumConfig.volume,
                "pitch": drumConfig.pitch
            ]
        case let cymbalConfig as CymbalConfiguration:
            return [
                "type": "cymbal",
                "cymbalType": cymbalConfig.cymbalType.rawValue,
                "volume": cymbalConfig.volume,
                "decay": cymbalConfig.decay
            ]
        case let noteConfig as NoteConfiguration:
            return [
                "type": "note",
                "note": noteConfig.note,
                "volume": noteConfig.volume,
                "duration": noteConfig.duration,
                "waveShape": noteConfig.waveShape.rawValue
            ]
        default:
            return ["type": "silent"]
        }
    }
}


// These aren't implemented here yet.
//class DrumItem: DraggableGameItem {
//    // Drum-specific properties and methods
//    func applyConfiguration(_ config: DrumConfiguration) {
//        audioConfiguration = config
//        // Additional drum-specific updates
//        updateVisuals()
//    }
//    
//    private func updateVisuals() {
//        // Update drum-specific visuals
//    }
//}
//
//class EmitterItem: DraggableGameItem {
//    // Emitter-specific properties
//    var emitterIndex: Int?
//    
//    func applyConfiguration(_ config: EmitterConfiguration) {
//        audioConfiguration = config
//        // Additional emitter-specific updates
//    }
//}
