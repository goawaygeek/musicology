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
    
    func handleTap()
    func handlePan(_ gesture: UIPanGestureRecognizer)
}
