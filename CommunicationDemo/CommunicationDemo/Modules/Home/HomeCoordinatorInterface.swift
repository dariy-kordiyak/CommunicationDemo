//
//  HomeCoordinatorInterface.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import Foundation

protocol HomeCoordinatorInterface: class {}
protocol HomeViewInput: class {
    func updateLabel(with message: String)
}
protocol HomeViewOutput: class {
    func viewDidFetchData()
    func actionButtonTapped()
}
protocol HomeViewDatasource: class {}

enum HomeModule {
    
    enum Event {
        case foo
        case bar
    }
    
}
