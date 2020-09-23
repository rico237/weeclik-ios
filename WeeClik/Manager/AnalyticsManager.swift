//
//  AnalyticsManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 30/12/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Analytics
import Parse

import Segment_Firebase
import Segment_Batch
import Segment_Flurry

class AnalyticsManager: NSObject {
    public static let shared = AnalyticsManager()
    private override init() {
        super.init()
        instanciate()
    }

    var isOptedIn: Bool {
        UserDefaultsManager.UserPreferences.rgpd
    }
    
    func instanciate() {
        let configuration = SEGAnalyticsConfiguration(writeKey: "1olLX7ZmFBXKkfF2t6uKzva9BGaQT8A1")
        // Enable this to record certain application events automatically!
        configuration.trackApplicationLifecycleEvents = true
        // Enable this to record screen views automatically!
        // configuration.recordScreenViews = true // Not working for now so should be added manually to all VCs
        
        // Add destinations
//        configuration.use(SEGFirebaseIntegrationFactory.instance())
//        configuration.use(SEGBatchIntegrationFactory.instance())
//        if let flurryInstance = SEGFlurryIntegrationFactory.instance() as? SEGFlurryIntegrationFactory {
//            configuration.use(flurryInstance)
//        }
        
        _ = SEGAnalytics(configuration: configuration)
    }
    
    func trackEvent(event: String, properties: [String: Any]? = [:], options: [String: Any]? = nil) {
        guard let segmentAnalytics = SEGAnalytics.shared(), isOptedIn else { return }
        // Init properties
        var trackedProperties: [String: Any] = [:]
        if let properties = properties { trackedProperties = properties }
        
        if ConfigurationManager.shared.isDev() {
            trackedProperties["env"] = "DEVELOPMENT"
        } else {
            trackedProperties["env"] = "PRODUCTION"
        }
        
        if let knownPosition = LatestKnowLocationManager.shared.getLatestPosition() {
            Log.all.verbose("Segment analytics tracked with location")
            
            trackedProperties["lat"] = knownPosition.coordinate.latitude
            trackedProperties["lng"] = knownPosition.coordinate.longitude
        } else {
            Log.all.verbose("Segment analytics tracked without location")
        }
        
        segmentAnalytics.track(event, properties: trackedProperties, options: options)
    }
    
    /// let user disable tracking of events
    func toggleTracking() {
        guard let segmentAnalytics = SEGAnalytics.shared() else { return }
        
        if isOptedIn {
            segmentAnalytics.enable()
            instanciate()
            Log.all.info("User re-enabled tracking of analytics")
        } else {
            segmentAnalytics.disable()
            Log.all.info("User disabled tracking of analytics")
        }
        
        UserDefaultsManager.UserPreferences.rgpd = !UserDefaultsManager.UserPreferences.rgpd
    }
    
    func trackUser(user: PFUser) {
        guard let segmentAnalytics = SEGAnalytics.shared() else { return }
        // Refresh user data
        user.fetchInBackground { (refreshedUser, error) in
            if let refreshedUser = refreshedUser as? PFUser {
                var userInfos: [String: Any] = [:]
                userInfos["email"] = refreshedUser.email
                userInfos["username"] = refreshedUser.username
                userInfos["sessionToken"] = refreshedUser.sessionToken
                segmentAnalytics.identify(refreshedUser.objectId, traits: userInfos)
            } else if error == nil {
                var userInfos: [String: Any] = [:]
                userInfos["email"] = user.email
                userInfos["username"] = user.username
                userInfos["sessionToken"] = user.sessionToken
                segmentAnalytics.identify(user.objectId, traits: userInfos)
            } else if let error = error {
                Log.all.error("Fetch of new user data failed with error: \(error.debug)")
            }
        }
    }
}
