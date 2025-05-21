//
//  CollisionProtocols.swift
//  Musicology
//
//  Created by Scott Brewer on 5/14/25.
//
import UIKit

protocol CollisionObject: AnyObject {
    var id: UUID { get }
    var collisionBounds: CGRect { get }
    var type: ItemType { get }
    var name: String? { get }
    
    // Optional methods that objects can implement if they need direct notification
    func willCollide(with ball: BallView) -> Bool  // Can veto collision
    func didCollide(with ball: BallView, at point: CGPoint)
}

// Add default implementations as an extension
extension CollisionObject {
    func willCollide(with ball: BallView) -> Bool {
        return true // Default is to allow collision
    }
    
    func didCollide(with ball: BallView, at point: CGPoint) {
        // Default empty implementation
        print(#function, "collided with \(name ?? "an object") at \(point)")
    }
}
