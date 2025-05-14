//
//  CollisionEventListener.swift
//  Musicology
//
//  Created by Scott Brewer on 5/14/25.
//
import UIKit

protocol CollisionEventListener: AnyObject {
    func onCollision(between ball: BallView, and object: CollisionObject, at point: CGPoint)
}
