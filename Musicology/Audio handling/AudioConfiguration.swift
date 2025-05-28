//
//  AudioConfiguration.swift
//  Musicology
//
//  Created by Scott Brewer on 5/22/25.
//

import Foundation

protocol AudioConfiguration {
    var volume: Float { get set }
    var identifier: String { get }
    
    func createSoundParameters() -> [String: Any]
}

// Specific audio configurations for each item type
struct DrumConfiguration: AudioConfiguration {
    var volume: Float = 1.0
    var drumType: DrumType = .snare
    var pitch: Float = 0.0 // -1.0 to 1.0 for pitch adjustment
    
    var identifier: String {
        return "drum_\(drumType.rawValue)"
    }
    
    func createSoundParameters() -> [String: Any] {
        return [
            "type": "drum",
            "drumType": drumType.rawValue,
            "volume": volume,
            "pitch": pitch
        ]
    }
    
    enum DrumType: String, CaseIterable {
        case snare, floor, rack, kick
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
}

struct CymbalConfiguration: AudioConfiguration {
    var volume: Float = 1.0
    var cymbalType: CymbalType = .hiHat
    var decay: Float = 0.5 // 0.0 to 1.0
    
    var identifier: String {
        return "cymbal_\(cymbalType.rawValue)"
    }
    
    func createSoundParameters() -> [String: Any] {
        return [
            "type": "cymbal",
            "cymbalType": cymbalType.rawValue,
            "volume": volume,
            "decay": decay
        ]
    }
    
    enum CymbalType: String, CaseIterable {
        case hiHat, crash, ride
        
        var displayName: String {
            switch self {
            case .hiHat: return "Hi-Hat"
            default: return rawValue.capitalized
            }
        }
    }
}

struct NoteConfiguration: AudioConfiguration {
    var volume: Float = 1.0
    var note: String = "C4"
    var duration: TimeInterval = 500 // milliseconds
    var waveShape: WaveShape = .sine
    
    var identifier: String {
        return "note_\(note)_\(waveShape.rawValue)"
    }
    
    func createSoundParameters() -> [String: Any] {
        return [
            "type": "note",
            "note": note,
            "volume": volume,
            "duration": duration,
            "waveShape": waveShape.rawValue
        ]
    }
    
    enum WaveShape: String, CaseIterable {
        case sine, square, sawtooth, triangle
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
}

struct EmitterConfiguration: AudioConfiguration {
    var bpm: Double = 1 // 60-220
    var velocity: CGFloat = 0.5 // 0-1
    var isStaggered: Bool = false
    var volume: Float = 0.5 // Add volume property
    
    var identifier: String { return "emitter" }
    
    func createSoundParameters() -> [String: Any] {
        return [
            "type": "emitter",
            "bpm": bpm,
            "velocity": velocity,
            "staggered": isStaggered,
            "volume": volume
        ]
    }
}
