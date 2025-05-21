//
//  TargetViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class TargetViewController: UIViewController, LabelProviding {
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Target", color: .systemPurple, style: .title1)
    }
}
