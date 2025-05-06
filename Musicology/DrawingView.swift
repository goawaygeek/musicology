//
//  DrawingView.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class DrawingView: UIView {
    private var currentPath: UIBezierPath?
    private var paths = [RecognizablePath]() // We'll implement this
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentPath = UIBezierPath()
        currentPath?.lineWidth = 3.0
        currentPath?.move(to: touch.location(in: self))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let path = currentPath else { return }
        path.addLine(to: touch.location(in: self))
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finalizePath()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finalizePath()
    }
    
    private func finalizePath() {
        guard let path = currentPath else { return }
        // TODO: Add recognition logic
        paths.append(RecognizablePath(path: path))
        currentPath = nil
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.label.setStroke()
        paths.forEach { $0.path.stroke() }
        currentPath?.stroke()
    }
}
