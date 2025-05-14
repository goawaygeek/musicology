//
//  BallView.swift
//  Musicology
//
//  Created by Scott Brewer on 5/8/25.
//
import UIKit

class BallView: UIView {
    private let color: UIColor
    var velocity: CGVector = .zero
    var lifetime: Int = 3 // Bounces before disappearing
    var recentCollisions: [UIView: TimeInterval] = [:]
    let collisionCooldown: TimeInterval = 0.5 // Half second cooldown
    var lastCollidedObject: UIView? = nil
        
    
    
    func updatePosition() {
        center.x += velocity.dx
        center.y += velocity.dy
    }
    
    init(color: UIColor = .systemRed, radius: CGFloat = 10) {
        self.color = color
        super.init(frame: CGRect(x: 0, y: 0, width: radius*2, height: radius*2))
        backgroundColor = .clear
        layer.cornerRadius = radius
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func canCollideWith(_ object: UIView) -> Bool {
        if lastCollidedObject === object {
            return false
        }
//        if let lastCollisionTime = recentCollisions[object],
//           currentTime - lastCollisionTime < collisionCooldown {
//            return false
//        }
        return true
    }
    
    func registerCollision(with object: UIView, at time: TimeInterval) {
        // recentCollisions[object] = time
        lastCollidedObject = object
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: bounds)
    }
}
