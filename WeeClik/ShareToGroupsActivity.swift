//
//  ShareToGroups.swift
//  WeeClik
//
//  Created by Herrick Wolber on 10/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit

class ShareToGroupsActivity: UIActivity {
    
    var _activityTitle: String
    var activityItems = [Any]()
    var action: ([Any]) -> Void
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    override func perform() {
        action(activityItems)
        activityDidFinish(true)
    }
    
    init(title: String, performAction: @escaping ([Any]) -> Void) {
        _activityTitle = title
        action = performAction
        super.init()
    }
    
    override var activityTitle: String? {
        return _activityTitle
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "Group_icon")
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: "fr.herrick-wolber.WeeClik.activity")
    }
    
    override class var activityCategory: UIActivityCategory {
        return .action
    }
}
