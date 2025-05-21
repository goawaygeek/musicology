//
//  EmitterPhysics.swift
//  Musicology
//
//  Created by Scott Brewer on 5/8/25.
//
import UIKit

struct EmitterConfiguration {
    var bpm: Double = 1 // 60-220
    var velocity: CGFloat = 0.5 // 0-1
    var isStaggered: Bool = false
}

class EmitterPhysics {
    private var displayLink: CADisplayLink?
    private var lastEmitTime: CFTimeInterval = 0
    private var config: EmitterConfiguration
    
    init(config: EmitterConfiguration) {
        self.config = config
    }
    
    func startEmitting(update: @escaping (CGVector, Int) -> Void) {
        lastEmitTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .common)
        
        // Store the callback
        self.emitCallback = update
    }
    
    func stopEmitting() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private var emitCallback: ((CGVector, Int) -> Void)?
    
    @objc private func step(displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        let interval = 60.0 / config.bpm
        
        if currentTime - lastEmitTime >= interval {
            print("ct: \(currentTime), lt: \(lastEmitTime), diff: \(currentTime - lastEmitTime), interval: \(interval), config: \(config)")
            emitBalls()
            lastEmitTime = currentTime
        }
    }
    
    private func emitBalls() {
        let directions = [
            CGVector(dx: 0, dy: -1),  // Up
            CGVector(dx: 1, dy: 0),   // Right
            CGVector(dx: 0, dy: 1),   // Down
            CGVector(dx: -1, dy: 0)    // Left
        ]
        
        for (index, direction) in directions.enumerated() {
            let delay = config.isStaggered ? Double(index) * 0.1 : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Scale the vector by the velocity
                let scaledDirection = CGVector(
                    dx: direction.dx * self.config.velocity,
                    dy: direction.dy * self.config.velocity
                )
                
                // Call back to the view controller with the direction and pipe index
                self.emitCallback?(scaledDirection, index)
            }
        }
    }
}
