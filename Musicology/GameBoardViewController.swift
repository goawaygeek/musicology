//
//  GameBoardViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class GameBoardViewController: UIViewController, LabelProviding {
    private let drawingView = DrawingView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLabel(text: "Game Board", color: .systemRed)
        setupDrawingView()
        
    }
    
    private func setupDrawingView() {
            drawingView.backgroundColor = .clear
            drawingView.isOpaque = false
            
            drawingView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(drawingView)
            
            NSLayoutConstraint.activate([
                drawingView.topAnchor.constraint(equalTo: view.topAnchor),
                drawingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                drawingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                drawingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
}

