//
//  HomeViewController.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import UIKit
import MessageUI

final class HomeViewController<Datasource, ViewOutput>: UIViewController, MFMailComposeViewControllerDelegate, Logging
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
    
    private let sendLogsButton: UIButton = {
        let ret = UIButton(type: .system)
        ret.setTitle("Send logs", for: .normal)
        ret.addTarget(self,
                      action: #selector(sendLogsTapped),
                      for: .touchUpInside)
        ret.translatesAutoresizingMaskIntoConstraints = false
        
        return ret
    }()
    
    private let emails = ["maksym.yalovol2@globallogic.com", "dariy.kordiyak@globallogic.com"]
    
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
    
    @IBAction private func sendLogsTapped() {
        // Construct the log attachment filename
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let dateString = formatter.string(from: Date())
        let email = "max/dariy"
        let filename = "log_\(email)_\(dateString).zip"
        
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        mailVC.setToRecipients(emails)
        mailVC.setSubject("Demo communication App Bug Report")
        mailVC.setMessageBody("bug report", isHTML: false)

        // Get the watchOS logging data
        SessionHandler.shared.getLogs { [weak self] (watchLogFileURL: URL?, error: Error?) in

            // Check and log any errors
            if let error = error {
                self?.log("Unable to fetch watchOS logs: \(error.localizedDescription)")
            }

            // Load the watch logs as an attachment
            if let watchLogFileURL = watchLogFileURL,
                let watchLogData = try? Data(contentsOf: watchLogFileURL) {
                self?.log("Successfully fetched watchOS logs")
                mailVC.addAttachmentData(watchLogData as Data, mimeType: "application/zip",
                                         fileName: "watchos_" + filename)
            }

            // Get iOS logs inside of the watchOS logs completion handler so that they
            // contain any log lines related to the fetching of watchOS logs.
            if let phoneLogFileURL = LoggingManager.shared.loggedDataZip,
                let phoneLogData = try? Data(contentsOf: phoneLogFileURL) {
                self?.log("Successfully zipped iOS logs")
                mailVC.addAttachmentData(phoneLogData, mimeType: "application/zip",
                                         fileName: "ios_" + filename)
            }

            // Present the compose mail view
            DispatchQueue.main.async {
                self?.present(mailVC, animated: true, completion: nil)
            }
        }
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
        
        view.addSubview(sendLogsButton)
        let sendLogsButtonConstraints = [sendLogsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                        sendLogsButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 50)
        ]
        NSLayoutConstraint.activate(sendLogsButtonConstraints)
    }

}

extension HomeViewController: HomeViewInput {
    
    func updateLabel(with message: String) {
        messageLabel.text = message
    }
    
}

