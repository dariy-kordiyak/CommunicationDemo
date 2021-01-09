//
//  CoordinatorInterface.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import UIKit

protocol RootableCoordinator {
    /// Intial controller of the module
    var rootController: UIViewController? { get }
}

/** Basic interface for coordinator.
    It describes all the available outside the module (for coordinator owner) */
protocol Coordinator: RootableCoordinator {

    /// Generic type of the data to compose initial screen
    associatedtype InputData

    /// Module's entry point. Call this method to start the module
    ///
    /// - Parameters:
    ///   - data: with this data the initial screen is configured
    ///   - presentingController: the initial controller is shown from it
    func start(with data: InputData,
               from presentingController: UIViewController)
}
