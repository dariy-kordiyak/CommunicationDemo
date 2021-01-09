//
//  HomePresenter.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import Foundation

final class HomePresenter: HomeViewDatasource, HomeViewOutput {
    
    typealias Event = HomeModule.Event
    typealias View = HomeViewInput
    
    // MARK: - Properties
    
    private let coordinator: HomeCoordinatorInterface
    weak var view: View?
    
    // MARK: - Initialization
    
    init(coordinator: HomeCoordinator) {
        self.coordinator = coordinator
    }
    
    // MARK: - HomeViewOutput
    
    func viewDidFetchData(_ view: View) {
        
    }
    
    func viewShouldClose(_ view: View) {
        
    }
    
    func view(_ view: View,
              itemIndex: IndexPath?,
              didProduceEvent event: Event) {
        
    }
    
}
