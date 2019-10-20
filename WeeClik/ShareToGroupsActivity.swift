//
//  ShareToGroups.swift
//  WeeClik
//
//  Created by Herrick Wolber on 10/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit

class ShareToGroupsActivity: UIActivity {

    var activityTitl: String
    var activityItems: [Any] = []
    var action: ([Any]) -> Void

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for case is String in activityItems { return true }
        return false
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }

    override func perform() {
        action(activityItems)
        activityDidFinish(true)
    }

    init(title: String, performAction: @escaping ([Any]) -> Void) {
        activityTitl = title
        action = performAction
        super.init()
    }

    override var activityTitle: String? {
        return activityTitl
    }

    override var activityImage: UIImage? {
        return UIImage(named: "Group_icon")
    }

    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType(rawValue: "com.ringosoftware.weeclik.activity")
    }

    override class var activityCategory: UIActivity.Category {
        return .action
    }
}
