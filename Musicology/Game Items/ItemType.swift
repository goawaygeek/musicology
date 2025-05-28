//
//  ItemType.swift
//  Musicology
//
//  Created by Scott Brewer on 5/7/25.
//
import UIKit

enum ItemType: String, CaseIterable {
    case emitter    // +
    case spring     // s
    case blackhole  // o
    case splitter   // triangle
    case drum       // U
    case cymbal     // =
    case note       // -
    
    var imageName: String {
        return self.rawValue + "_icon" // e.g. "emitter_icon.png"
    }
    
    var displayName: String {
        return self.rawValue.capitalized
    }
    
    // Factory method for default audio configurations
    func createDefaultAudioConfiguration() -> AudioConfiguration {
        switch self {
        case .drum:
            return DrumConfiguration()
        case .cymbal:
            return CymbalConfiguration()
        case .note:
            return NoteConfiguration()
        default:
            // For non-audio items, could return a silent configuration
            return SilentConfiguration()
        }
    }
}

// For items that don't produce sound
struct SilentConfiguration: AudioConfiguration {
    var volume: Float = 0.0
    var identifier: String = "silent"
    
    func createSoundParameters() -> [String: Any] {
        return ["type": "silent"]
    }
}
