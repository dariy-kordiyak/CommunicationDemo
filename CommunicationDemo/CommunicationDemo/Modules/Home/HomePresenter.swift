//
//  HomePresenter.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import Foundation

final class HomePresenter: HomeViewDatasource, HomeViewOutput, Logging {
    
    typealias Event = HomeModule.Event
    typealias View = HomeViewInput
    
    // MARK: - Properties
    
    private var sessionHandler = SessionHandler.shared
    private var healthKitManager = HealthKitHandler.shared
    private let coordinator: HomeCoordinatorInterface
    
    private var timer: Timer?
    private var timerRunCount = 0
    
    weak var view: View?
    
    // MARK: - Initialization
    
    init(coordinator: HomeCoordinator) {
        self.coordinator = coordinator
        sessionHandler.delegate = self
    }
    
    // MARK: - HomeViewOutput
    
    func viewDidFetchData() {
        healthKitManager.authorizeHealthKit { [weak self] (_, _) in
            guard let self = self else { return }
            self.healthKitManager.start()
            self.timer = Timer(timeInterval: 12,
                                target: self,
                                selector: #selector(self.timerFired),
                                userInfo: nil,
                                repeats: true)
        }
    }
        
    func view(_ view: View,
              itemIndex: IndexPath?,
              didProduceEvent event: Event) {
        
    }
    
    func actionButtonTapped() {
        log("HomePresenter -> actionButtonTapped")
        sendMessageToWatch(parameter: "action button")
    }
    
    // MARK: - Actions
    
    @objc private func timerFired() {
        log("HomePresenter -> timerFired")
        timerRunCount += 1
        if timerRunCount == 15 {
            log("HomePresenter -> timer invalidated")
            timer?.invalidate()
        }
        else {
            sendMessageToWatch(parameter: "\(timerRunCount)")
        }
    }
    
    private func sendMessageToWatch(parameter: String) {
        let message: [String: Any] = ["key": "from phone: \(parameter)"]
        sessionHandler.wcSession.sendMessage(message,
                                             replyHandler: nil) { [weak self] error in
            self?.log("HomePresenter -> error sending message: \(error)")
        }
    }
    
}

extension HomePresenter: SessionHandlerDelegate {
    
    func sessionHandler(_ hander: SessionHandler,
                        didReceiveMessage message: String) {
        DispatchQueue.main.async {
            self.view?.updateLabel(with: message)
        }
    }
    
}
