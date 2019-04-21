//
//  BlurredStatusBarViewController.swift
//  Hacker News
//
//  Created by Trevor Behlman on 4/21/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import UIKit

class BlurredStatusBarViewController: UIViewController {
    override func viewDidLoad() {
        let child = TopStoriesViewController()
        addChild(child)
        view.addSubview(child.view)
        child.view.frame = view.bounds
        
        // Add blur effect on status bar
        let blurEffect = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurEffectView)
        blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        blurEffectView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        blurEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        blurEffectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
}
