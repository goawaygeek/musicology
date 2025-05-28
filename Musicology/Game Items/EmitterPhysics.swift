//
//  EmitterPhysics.swift
//  Musicology
//
//  Created by Scott Brewer on 5/8/25.
//
import UIKit

//struct EmitterConfiguration {
//    var bpm: Double = 1 // 60-220
//        var velocity: CGFloat = 0.5 // 0-1
//        var isStaggered: Bool = false
//        var volume: Float = 0.5 // Add volume property
//        
//        var identifier: String { return "emitter" }
//        
//        func createSoundParameters() -> [String: Any] {
//            return [
//                "type": "emitter",
//                "bpm": bpm,
//                "velocity": velocity,
//                "staggered": isStaggered,
//                "volume": volume
//            ]
//        }
//}

class EmitterPhysics {
    private var displayLink: CADisplayLink?
    private var lastEmitTime: CFTimeInterval = 0
    private var config: EmitterConfiguration
    private let configQueue = DispatchQueue(label: "config.queue", attributes: .concurrent)
    private var currentInterval: TimeInterval {
            return 60.0 / config.bpm
        }
    
    init(config: EmitterConfiguration) {
        self.config = config
    }
    
    // Thread-safe config access
    func updateConfig(_ newConfig: EmitterConfiguration) {
        configQueue.async(flags: .barrier) {
            self.config = newConfig
        }
    }
    
    private func getConfig() -> EmitterConfiguration {
        return configQueue.sync { config }
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
        let currentConfig = getConfig() // Thread-safe access
        let currentTime = displayLink.timestamp
        //let interval = 60.0 / currentConfig.bpm
        let beatsElapsed = (currentTime - lastEmitTime) / currentInterval
        
        if beatsElapsed >= 1.0 {
            emitBalls(with: currentConfig)
            lastEmitTime = currentTime - (currentInterval * (beatsElapsed - 1.0))
        }
        
//        if currentTime - lastEmitTime >= interval {
//            emitBalls(with: currentConfig)
//            lastEmitTime = currentTime
//        }
    }
    
    private func emitBalls(with config: EmitterConfiguration) {
        let directions = [CGVector(dx: 0, dy: -1), CGVector(dx: 1, dy: 0),
                         CGVector(dx: 0, dy: 1), CGVector(dx: -1, dy: 0)]
        
        for (index, direction) in directions.enumerated() {
            let delay = config.isStaggered ? Double(index) * 0.1 : 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let scaledDirection = direction * config.velocity
                self.emitCallback?(scaledDirection, index)
            }
        }
    }
}
