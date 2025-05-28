//
//  EditPanelViewDelegate.swift
//  Musicology
//
//  Created by Scott Brewer on 5/22/25.
//
import Foundation

//protocol EditPanelDelegate: AnyObject {
//    func editPanel(_ panel: EditPanelViewController, didUpdateConfiguration configuration: AudioConfiguration, for item: GameItem)
//    //func editPanelDidRequestClose(_ panel: EditPanelViewController)
//    func editPanel(_ panel: EditPanelViewController, didRequestTestSound for: GameItem)
//}

protocol EditPanelDelegate: AnyObject {
    // Unified configuration update method
    func editPanel(_ panel: EditPanelViewController,
                   didUpdateConfiguration configuration: AudioConfiguration,
                   for item: GameItem)
    
    // Type-specific update methods
    func editPanel(_ panel: EditPanelViewController,
                   didUpdateEmitterConfiguration config: EmitterConfiguration,
                   for item: GameItem)
    
    func editPanel(_ panel: EditPanelViewController,
                   didUpdateDrumConfiguration config: DrumConfiguration,
                   for item: GameItem)
    
    // Add more type-specific methods as needed
    func editPanelDidRequestTestSound(_ panel: EditPanelViewController, item: GameItem)
}
