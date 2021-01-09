//
//  HomeCoordinator.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import UIKit

final class HomeCoordinator: Coordinator, HomeCoordinatorInterface {
    
    // MARK: - Properties
    
    weak var rootController: UIViewController?
    
    // MARK: - API
    
    func start(with data: String, from presentingController: UIViewController) {}
    
    func makeViewController() -> UIViewController {
        let homePresenter = HomePresenter(coordinator: self)
        let homeController = HomeViewController(dataSource: homePresenter,
                                                eventsHandler: homePresenter)
        homePresenter.view = homeController
        
        rootController = homeController

        return homeController
    }
    
}
