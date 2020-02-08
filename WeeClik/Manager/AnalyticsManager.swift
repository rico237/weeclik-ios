//
//  AnalyticsManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 30/12/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Analytics

class AnalyticsManager: NSObject {
    public static let shared = AnalyticsManager()
    private override init() {
        super.init()
        instanciate()
    }
    
    func instanciate() {
        let configuration = SEGAnalyticsConfiguration(writeKey: "F7pNWprHAOUpg4JiI2vAjaqVJxSntHHg")
        // Enable this to record certain application events automatically!
        configuration.trackApplicationLifecycleEvents = true
        // Enable this to record screen views automatically!
        configuration.recordScreenViews = true
        
        _ = SEGAnalytics(configuration: configuration)
    }
    
    func trackEvent(event: String, properties: [String: Any]? = [:], options: [String: Any]? = nil) {
        guard let segmentAnalytics = SEGAnalytics.shared() else { return }
        
        if let knownPosition = LatestKnowLocationManager.shared.getLatestPosition(),
           var properties = properties {
            properties["lat"] = knownPosition.coordinate.latitude
            properties["lng"] = knownPosition.coordinate.longitude
        }
        
        segmentAnalytics.track(event, properties: properties, options: options)
    }
}
