//
//  GameItemDelegate.swift
//  Musicology
//
//  Created by Scott Brewer on 5/16/25.
//
protocol GameItemDelegate: AnyObject {
    func gameItemDidCollide(_ item: GameItem)
}
