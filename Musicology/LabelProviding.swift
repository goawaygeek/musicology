//
//  LabelProviding.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//

// LabelProviding.swift
import UIKit

protocol LabelProviding: AnyObject {
    func addLabel(text: String, color: UIColor, style: UIFont.TextStyle)
}

extension LabelProviding where Self: UIViewController {
    func addLabel(text: String, color: UIColor, style: UIFont.TextStyle = .largeTitle) {
        let label = UILabel()
        label.text = text
        label.textColor = color
        label.font = .preferredFont(forTextStyle: style)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
}
