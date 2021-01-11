//
//  TimeUtility.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 09.01.2021.
//

import Foundation

extension Timer {
    
    @discardableResult
    static func scheduledTimerOnMainLoop(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
        RunLoop.main.add(timer, forMode: .default)
        return timer
    }

    @discardableResult
    static func scheduledTimerOnMainLoop(timeInterval ti: TimeInterval,
                                         target aTarget: Any,
                                         selector aSelector: Selector,
                                         userInfo: Any?,
                                         repeats yesOrNo: Bool) -> Timer {
        let timer = Timer(timeInterval: ti, target: aTarget, selector: aSelector, userInfo: userInfo, repeats: yesOrNo)
        RunLoop.main.add(timer, forMode: .default)
        return timer
    }
    
}
