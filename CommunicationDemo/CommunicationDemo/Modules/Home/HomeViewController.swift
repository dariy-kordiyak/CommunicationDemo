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
        
        view.backgroundColor = .red
    }


}

extension HomeViewController: HomeViewInput {
    
}

