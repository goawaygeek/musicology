//
//  OutputViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//

import UIKit

class OutputViewController: UIViewController, LabelProviding {
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Output", color: .systemGreen, style: .title1)
    }
}

