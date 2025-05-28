//
//  GameItem.swift
//  Musicology
//
//  Created by Scott Brewer on 5/7/25.
//

import UIKit

protocol GameItem: AnyObject {
    var type: ItemType { get }
    var position: CGPoint { get set }
    var view: UIView { get }
    var audioConfiguration: AudioConfiguration { get set }
    
    func handleTap()
    func handlePan(_ gesture: UIPanGestureRecognizer)
    func handleCollision()
}

extension GameItem {
    func handleCollision() {
        // This will be called by CollisionManager
        // Post notification with audio configuration for SoundEngine
        NotificationCenter.default.post(
            name: .itemCollisionOccurred,
            object: self,
            userInfo: ["audioConfiguration": audioConfiguration]
        )
    }
}

// Notification for collision events
extension Notification.Name {
    static let itemCollisionOccurred = Notification.Name("itemCollisionOccurred")
}
