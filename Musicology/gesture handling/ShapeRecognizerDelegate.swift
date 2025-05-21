//
//  ShapeRecognizerDelegate.swift
//  Musicology
//
//  Created by Scott Brewer on 5/7/25.
//
import UIKit

protocol ShapeRecognizerDelegate: AnyObject {
    func didRecognizeShape(_ type: ItemType, at position: CGPoint)
}
