/**
 *  BulletinBoard
 *  Copyright (c) 2017 Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import BLTNBoard

/**
 * A set of tools to interact with the demo data.
 *
 * This demonstrates how to create and configure bulletin items.
 */

enum BulletinDataSource {

    // MARK: - Pages

    static func makeFilterPage() -> BLTNPageItem {

        let page = BLTNPageItem(title: "Préférence de filtrage".localized())
        page.image = #imageLiteral(resourceName: "icon")
        page.imageAccessibilityLabel = "⚠️"

        page.descriptionText = "Vous avez choisit pour le moment d'afficher les commerces en fonction de votre position".localized()
        page.actionButtonTitle = "Trier par position".localized()
        page.alternativeButtonTitle = "Trier par nombre de partage".localized()
        page.requiresCloseButton = false
        page.isDismissable = true

        return page
    }

    static func makeFilterNextPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Filtre enregistré".localized())
        page.imageAccessibilityLabel = "⚠️"

        page.descriptionText = "Filtre enregistré avec succès, la liste des commerces va maintenant être rechargé".localized()
        page.actionButtonTitle = "OK".localized()
        page.requiresCloseButton = false
        page.isDismissable = true

        return page
    }

    /**
     * Create the introduction page.
     *
     * This creates a `FeedbackPageBulletinItem` with: a title, an image, a description text and
     * and action button.
     *
     * The action button presents the next item (the notification page).
     */

    static func makeIntroPage() -> BLTNPageItem {

        let page = BLTNPageItem(title: "Welcome to Instanimal")
        page.image = #imageLiteral(resourceName: "icon")
        page.imageAccessibilityLabel = "⚠️"

        page.descriptionText = "Discover curated images of the best pets in the world."
        page.actionButtonTitle = "Configure"

        page.isDismissable = false

        page.actionHandler = { item in
            item.manager?.displayNextItem()
        }

        page.next = makeNotitificationsPage()

        return page

    }

    /**
     * Create the notifications page.
     *
     * This creates a `FeedbackPageBulletinItem` with: a title, an image, a description text, an action
     * and an alternative button.
     *
     * The action and the alternative buttons present the next item (the location page). The action button
     * starts a notification registration request.
     */

    static func makeNotitificationsPage() -> BLTNPageItem {

        let page = BLTNPageItem(title: "Push Notifications")
        page.image = #imageLiteral(resourceName: "Certificate_valid_icon")
        page.imageAccessibilityLabel = "Notifications Icon"

        page.descriptionText = "Receive push notifications when new photos of pets are available."
        page.actionButtonTitle = "Subscribe"
        page.alternativeButtonTitle = "Not now"

        page.isDismissable = false

        page.actionHandler = { item in
            item.manager?.displayNextItem()
        }

        page.alternativeHandler = { item in
            item.manager?.displayNextItem()
        }

        page.next = makeLocationPage()

        return page

    }

    /**
     * Create the location page.
     *
     * This creates a `FeedbackPageBulletinItem` with: a title, an image, a compact description text,
     * an action and an alternative button.
     *
     * The action and the alternative buttons present the next item (the animal choice page). The action button
     * requests permission for location.
     */

    static func makeLocationPage() -> BLTNPageItem {

        let page = BLTNPageItem(title: "Customize Feed")
        page.image = #imageLiteral(resourceName: "Certificate_valid_icon")
        page.imageAccessibilityLabel = "Location Icon"

        page.descriptionText = "We can use your location to customize the feed. This data will be sent to our servers anonymously. You can update your choice later in the app settings."
        page.actionButtonTitle = "Send location data"
        page.alternativeButtonTitle = "No thanks"

        page.isDismissable = false

        page.actionHandler = { item in
            item.manager?.displayNextItem()
        }

        page.alternativeHandler = { item in
            item.manager?.displayNextItem()
        }

        page.next = makeCompletionPage()

        return page

    }

    /**
     * Create the location page.
     *
     * This creates a `PageBulletinItem` with: a title, an image, a description text, and an action
     * button. The item can be dismissed. The tint color of the action button is customized.
     *
     * The action button dismisses the bulletin. The alternative button pops to the root item.
     */

    static func makeCompletionPage() -> BLTNPageItem {

        let page = BLTNPageItem(title: "Setup Completed")
        page.image = #imageLiteral(resourceName: "Certificate_valid_icon")
        page.imageAccessibilityLabel = "Checkmark"
        page.appearance.actionButtonColor = #colorLiteral(red: 0.2941176471, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        page.appearance.alternativeButtonTitleColor = #colorLiteral(red: 0.2941176471, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        page.appearance.actionButtonTitleColor = .white

        page.descriptionText = "Instanimal is ready for you to use. Happy browsing!"
        page.actionButtonTitle = "Get started"
        page.alternativeButtonTitle = "Replay"

        page.isDismissable = true

        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }

        page.alternativeHandler = { item in
            item.manager?.popToRootItem()
        }

        return page

    }
}
