//
//  OutputViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//

import UIKit

// PlayControlDelegate.swift
protocol PlayControlDelegate: AnyObject {
    func playStateChanged(isPlaying: Bool)
}

// OutputViewController.swift
class OutputViewController: UIViewController, LabelProviding {
    weak var delegate: PlayControlDelegate?
    private var isPlaying = false
    
    private lazy var playButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "play.fill"), for: .normal)
        btn.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Output", color: .systemGreen, style: .title1)
        setupPlayButton()
    }
    
    private func setupPlayButton() {
        view.addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate 10% of the view width for right margin
        // We'll use the layoutMarginsGuide for a more reliable approach
        NSLayoutConstraint.activate([
            // Position 10% from the right edge
            playButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -view.frame.width * 0.1),
            // Center vertically in the view
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 50),
            playButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Make the button larger and more prominent
        playButton.tintColor = .systemGreen
        playButton.contentVerticalAlignment = .fill
        playButton.contentHorizontalAlignment = .fill
        playButton.imageView?.contentMode = .scaleAspectFit
    }
    
    @objc private func togglePlay() {
        isPlaying.toggle()
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
        delegate?.playStateChanged(isPlaying: isPlaying)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update the trailing constraint to be 10% of the current view width
        playButton.constraints.forEach { constraint in
            if constraint.firstAttribute == .trailing {
                constraint.constant = -view.bounds.width * 0.1
            }
        }
    }
}

