//
//  EmitterItem.swift
//  Musicology
//
//  Created by Scott Brewer on 5/8/25.
//
import UIKit

class EmitterItem: DraggableGameItem {
    // MARK: - Properties
    private var _bpm: Float = 120 {
        didSet {
            _bpm = min(max(_bpm, 60), 220)
            notifyConfigurationUpdate()
        }
    }
    
    private var _velocity: Float = 0.5 {
        didSet {
            _velocity = min(max(_velocity, 0), 1)
            notifyConfigurationUpdate()
        }
    }
    
    private var _isStaggered: Bool = false {
        didSet {
            notifyConfigurationUpdate()
        }
    }
    
    // MARK: - Public Interface
    var bpm: Float {
        get { _bpm }
        set { _bpm = newValue }
    }
    
    var velocity: Float {
        get { _velocity }
        set { _velocity = newValue }
    }
    
    var isStaggered: Bool {
        get { _isStaggered }
        set { _isStaggered = newValue }
    }
    
    // MARK: - Configuration Management
    override var audioConfiguration: AudioConfiguration {
        get {
            return currentEmitterConfiguration()
        }
        set {
            guard let config = newValue as? EmitterConfiguration else { return }
            updateFromConfiguration(config)
        }
    }
    
    private func currentEmitterConfiguration() -> EmitterConfiguration {
        return EmitterConfiguration(
            bpm: Double(_bpm),
            velocity: CGFloat(_velocity),
            isStaggered: _isStaggered
        )
    }
    
    private func updateFromConfiguration(_ config: EmitterConfiguration) {
        // Temporarily remove observers to prevent loops
        _bpm = Float(config.bpm)
        _velocity = Float(config.velocity)
        _isStaggered = config.isStaggered
    }
    
    private func notifyConfigurationUpdate() {
        // let newConfig = currentEmitterConfiguration()
        delegate?.gameItemDidUpdate(self)
        
        // Optional: Update visuals if needed
        updateEmitterVisuals()
    }
    
    private func updateEmitterVisuals() {
        // Update any emitter-specific visuals here
    }
    
    // MARK: - Initialization
    override init(type: ItemType, frame: CGRect) {
        super.init(type: type, frame: frame)
        guard type == .emitter else { return }
        setupEmitterAppearance()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEmitterAppearance() {
        // Your existing emitter visual setup
        let glowLayer = CALayer()
        glowLayer.frame = bounds.insetBy(dx: -5, dy: -5)
        glowLayer.contents = UIImage(named: "emitter_glow")?.cgImage
        layer.addSublayer(glowLayer)
    }
}


/*class EmitterItem: DraggableGameItem {
    // Emitter-specific properties
    var bpm: Int = 30 {
        didSet { bpm = min(max(bpm, 60), 220) } // Clamp to range
    }
    
    var velocity: Float = 0.5 {
        didSet { velocity = min(max(velocity, 0), 1) }
    }
    
    @Published var isStaggered: Bool = false {
        didSet { updateEmitterConfiguration() }
    }
    
    private var emitterConfiguration: EmitterConfiguration {
        return EmitterConfiguration(
            bpm: Double(bpm),
            velocity: CGFloat(velocity),
            isStaggered: isStaggered
        )
    }
    
    // Override audioConfiguration to return our EmitterConfiguration
    override var audioConfiguration: AudioConfiguration {
        get {
            return emitterConfiguration as AudioConfiguration
        }
        set {
            // When the edit panel updates the configuration, extract the values
            if let emitterConfig = newValue as? EmitterConfiguration {
                self.bpm = Int(emitterConfig.bpm)
                self.velocity = Float(emitterConfig.velocity)
                self.isStaggered = emitterConfig.isStaggered
            }
        }
    }
    
    private func updateEmitterConfiguration() {
        // This ensures the parent class knows the configuration changed
        // You might need to notify delegates or update UI here
        print("updating emitter configuration")
        // FIXME: causing a crash
        let newConfig = EmitterConfiguration(
            bpm: Double(bpm),
            velocity: CGFloat(velocity),
            isStaggered: isStaggered
        )
        audioConfiguration = newConfig
        //delegate?.gameItemDidUpdate(self)
    }
    
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
}*/
