//
//  ViewController.swift
//  LangChat
//
//  Created by Robin Hutchinson on 2025-09-26.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialView()
    }

    private func setupInitialView() {
        view.backgroundColor = .systemBackground

        let matchVC = MatchViewController()

        addChild(matchVC)
        view.addSubview(matchVC.view)
        matchVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            matchVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            matchVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            matchVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            matchVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        matchVC.didMove(toParent: self)
    }
}

