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
    let id = UUID()
    var lifetime = 1 // set to 0 to remove ball from view.
    
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
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: bounds)
    }
}
