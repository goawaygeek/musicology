//
//  EditPanelViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class EditPanelViewController: UIViewController, LabelProviding {
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Edit Panel", color: .systemBlue)
    }
}
