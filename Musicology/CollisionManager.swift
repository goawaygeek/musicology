//
//  CollisionManager.swift
//  Musicology
//
//  Created by Scott Brewer on 5/14/25.
//
// TODO: contemplate making objects single tap or multitap somehow, the cooldown period works, but it could be better, set to 0.5 it takes 1.5 seconds for the ball to move through the rect of the object view so you end up with 3 triggers, it is kinda ugly.
import UIKit

class CollisionManager {
    private var listeners: [UUID: (WeakRef<AnyObject>, (BallView, CollisionObject, CGPoint) -> Void)] = [:]
    private var recentCollisions: [UUID: [UUID: TimeInterval]] = [:]
    private let cooldownPeriod: TimeInterval = 2.5
    
    func registerListener(_ listener: CollisionEventListener) -> UUID {
        let id = UUID()
        listeners[id] = (
            WeakRef(listener as AnyObject),
            { [weak listener] ball, object, point in
                listener?.onCollision(between: ball, and: object, at: point)
            }
        )
        return id
    }
    
    func unregisterListener(id: UUID) {
        listeners.removeValue(forKey: id)
    }
    
    func checkCollisions(balls: [BallView], objects: [CollisionObject]) {
        let currentTime = CACurrentMediaTime()
        
        for ball in balls {
            let ballId = ball.id
            
            for object in objects {
                let objectId = object.id
                
                // Check cooldown
                if let ballCollisions = recentCollisions[ballId],
                   let lastCollision = ballCollisions[objectId],
                   currentTime - lastCollision < cooldownPeriod {
                    continue
                }
                
                // Check spatial collision
                if ball.frame.intersects(object.collisionBounds) {
                    // Ask the object if it wants to veto this collision
                    if object.willCollide(with: ball) == false {
                        continue
                    }
                    
                    // Record this collision
                    // TODO: check these are getting removed when the ball goes away
                    if recentCollisions[ballId] == nil {
                        recentCollisions[ballId] = [:]
                    }
                    recentCollisions[ballId]?[objectId] = currentTime
                    
                    // Calculate collision point
                    let collisionPoint = calculateCollisionPoint(ball: ball, object: object)
                    
                    // Notify the object directly
                    object.didCollide(with: ball, at: collisionPoint)
                    
                    // Notify all listeners
                    notifyListeners(ball: ball, object: object, point: collisionPoint)
                }
            }
        }
    }
    
    private func calculateCollisionPoint(ball: BallView, object: CollisionObject) -> CGPoint {
        // Simplified - just return the ball's center for now
        return ball.center
    }
    
    private func notifyListeners(ball: BallView, object: CollisionObject, point: CGPoint) {
        for (id, listenerPair) in listeners {
            let (weakRef, callback) = listenerPair
            
            if weakRef.value != nil {
                // The listener still exists, so call its method using the stored closure
                callback(ball, object, point)
            } else {
                // Clean up any deallocated listeners
                listeners.removeValue(forKey: id)
            }
        }
    }
}

// Helper class to hold weak references
private class WeakRef<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}
