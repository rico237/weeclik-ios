//
//  Scheduler.swift
//  WeeClik
//
//  Created by Herrick Wolber on 03/05/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import Foundation
import UIKit

protocol Schedulable {
    var block: () -> Void {get}
    var timeInterval: TimeInterval {get}
}

public class Scheduler: NSObject {
    
    var timer: Timer?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc private func applicationWillResignActive(_ notification: Notification) {
        self.stop()
    }
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        self.start()
    }
    
    @objc func start() {
        self.stop()
        self.scheduleTimer()
        self.callback()
    }
    
    @objc func stop() {
        timer?.invalidate()
    }
    
    func restart() {
        self.stop()
        self.scheduleTimer()
    }
    
    private func scheduleTimer() {
        if let scheduler = self as? Schedulable {
            timer = Timer.scheduledTimer(timeInterval: scheduler.timeInterval, target: self, selector: #selector(callback), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func callback() {
        if let scheduler = self as? Schedulable {
            scheduler.block()
            self.restart()
        }
    }
}
