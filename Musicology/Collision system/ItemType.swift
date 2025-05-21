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
}
