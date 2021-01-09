//
//  HomeCoordinatorInterface.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import Foundation

protocol HomeCoordinatorInterface: class {}
protocol HomeViewInput: class {}
protocol HomeViewOutput: class {}
protocol HomeViewDatasource: class {}

enum HomeModule {
    
    enum Event {
        case foo
        case bar
    }
    
}
