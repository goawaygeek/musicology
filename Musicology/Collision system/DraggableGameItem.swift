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
    
    private var tapGesture: UITapGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    
    override init(type: ItemType, frame: CGRect) {
        id = UUID()
        //collisionBounds = frame
        super.init(type: type, frame: frame)
        setupGestures()
        self.name = type.displayName
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
        
        // TODO: Trigger edit panel display
        print("Selected \(type.displayName) for editing")
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
    }
}
