//
//  EmitterItem.swift
//  Musicology
//
//  Created by Scott Brewer on 5/8/25.
//
import UIKit

class EmitterItem: DraggableGameItem {
    // Emitter-specific properties
    var bpm: Int = 30 {
        didSet { bpm = min(max(bpm, 60), 220) } // Clamp to range
    }
    
    var velocity: Float = 0.5 {
        didSet { velocity = min(max(velocity, 0), 1) }
    }
    
    var isStaggered: Bool = false
    
    // Emitter visual customization
    override init(type: ItemType, frame: CGRect) {
        super.init(type: type, frame: frame)
        guard type == .emitter else { return }
        setupEmitterAppearance()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEmitterAppearance() {
        // Add emitter-specific visuals
        let glowLayer = CALayer()
        glowLayer.frame = bounds.insetBy(dx: -5, dy: -5)
        glowLayer.contents = UIImage(named: "emitter_glow")?.cgImage
        layer.addSublayer(glowLayer)
    }
}
