//
//  HomeViewController.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import UIKit

final class HomeViewController<Datasource, ViewOutput>: UIViewController
where Datasource: HomeViewDatasource, ViewOutput: HomeViewOutput
{
    
    // MARK: - Properties
    
    private let actionButton: UIButton = {
        let ret = UIButton(type: .system)
        ret.setTitle("Send message to Watch", for: .normal)
        ret.addTarget(self,
                      action: #selector(actionButtonTapped(_:)),
                      for: .touchUpInside)
        ret.translatesAutoresizingMaskIntoConstraints = false
        
        return ret
    }()
    
    private let messageLabel: UILabel = {
        let ret = UILabel()
        ret.text = "No messages from Watch yet"
        ret.translatesAutoresizingMaskIntoConstraints = false
        
        return ret
    }()
    
    private let dataSource: Datasource
    private let eventsHandler: ViewOutput
    
    // MARK: - Initialization
    
    init(dataSource: Datasource, eventsHandler: ViewOutput) {
        self.dataSource = dataSource
        self.eventsHandler = eventsHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        eventsHandler.viewDidFetchData()
    }

    // MARK: - Actions
    
    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        eventsHandler.actionButtonTapped()
    }
    
    // MARK: - Private
    
    private func setupView() {
        view.backgroundColor = .yellow
        
        view.addSubview(actionButton)
        let buttonConstraints = [actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                 actionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        NSLayoutConstraint.activate(buttonConstraints)
        
        view.addSubview(messageLabel)
        let labelConstraints = [messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                messageLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 50)
        ]
        NSLayoutConstraint.activate(labelConstraints)
    }

}

extension HomeViewController: HomeViewInput {
    
    func updateLabel(with message: String) {
        messageLabel.text = message
    }
    
}

