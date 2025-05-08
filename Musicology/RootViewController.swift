//
//  RottViewController.swift
//  Musicology
//
//  Created by Scott Brewer on 5/6/25.
//
import UIKit

class RootViewController: UIViewController {
    
    // MARK: - Child Controllers
    private lazy var targetVC: TargetViewController = {
        let vc = TargetViewController()
        return vc
    }()
    
    private lazy var gameBoardVC: GameBoardViewController = {
        let vc = GameBoardViewController()
        return vc
    }()
    
    private lazy var editPanelVC: EditPanelViewController = {
        let vc = EditPanelViewController()
        return vc
    }()
    
    private lazy var outputVC: OutputViewController = {
        let vc = OutputViewController()
        vc.delegate = gameBoardVC
        return vc
    }()
    
    // MARK: - Layout Constants
    private enum Layout {
        static let targetHeight: CGFloat = 120
        static let outputHeight: CGFloat = 120
        static let editPanelWidth: CGFloat = 200
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewHierarchy()
        styleViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        positionViews()
    }
    
    // MARK: - Setup
    private func setupViewHierarchy() {
        addChildVC(targetVC)
        addChildVC(gameBoardVC)
        addChildVC(editPanelVC)
        addChildVC(outputVC)
    }
    
    private func addChildVC(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    // MARK: - Layout
    private func positionViews() {
        let safeArea = view.safeAreaInsets
        
        // Target View (Top)
        targetVC.view.frame = CGRect(
            x: safeArea.left,
            y: safeArea.top,
            width: view.bounds.width - safeArea.left - safeArea.right,
            height: Layout.targetHeight
        )
        
        // Output View (Bottom)
        outputVC.view.frame = CGRect(
            x: safeArea.left,
            y: view.bounds.height - Layout.outputHeight - safeArea.bottom,
            width: view.bounds.width - safeArea.left - safeArea.right,
            height: Layout.outputHeight
        )
        
        // Game Board (Middle Left)
        gameBoardVC.view.frame = CGRect(
            x: safeArea.left,
            y: targetVC.view.frame.maxY,
            width: view.bounds.width - Layout.editPanelWidth - safeArea.left - safeArea.right,
            height: outputVC.view.frame.minY - targetVC.view.frame.maxY
        )
        
        // Edit Panel (Middle Right)
        editPanelVC.view.frame = CGRect(
            x: gameBoardVC.view.frame.maxX,
            y: targetVC.view.frame.maxY,
            width: Layout.editPanelWidth,
            height: outputVC.view.frame.minY - targetVC.view.frame.maxY
        )
    }
    
    // MARK: - Styling
    private func styleViews() {
        view.backgroundColor = .systemBackground
        
        // Add borders between sections
        addBorder(to: targetVC.view, edge: .bottom)
        addBorder(to: outputVC.view, edge: .top)
        addBorder(to: editPanelVC.view, edge: .left)
        
        targetVC.view.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        gameBoardVC.view.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        editPanelVC.view.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        outputVC.view.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
    }
    
    private func addBorder(to view: UIView, edge: UIRectEdge) {
        let border = UIView()
        border.backgroundColor = .separator
        border.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(border)
        
        switch edge {
        case .bottom:
            NSLayoutConstraint.activate([
                border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                border.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                border.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale) 
            ])
        case .top:
            NSLayoutConstraint.activate([
                border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                border.topAnchor.constraint(equalTo: view.topAnchor),
                border.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
            ])
        case .left:
            NSLayoutConstraint.activate([
                border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                border.topAnchor.constraint(equalTo: view.topAnchor),
                border.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                border.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
            ])
        default: break
        }
    }
}
