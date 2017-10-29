/**
 *  BulletinBoard
 *  Copyright (c) 2017 Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import BulletinBoard

/**
 * A set of tools to interact with the demo data.
 *
 * This demonstrates how to create and configure bulletin items.
 */

enum BulletinDataSource {

    // MARK: - Pages
    
    static func makeFilterPage(isLocation : Bool) -> PageBulletinItem {
        
        let page = PageBulletinItem(title: "Préférence de filtrage")
        page.image = #imageLiteral(resourceName: "icon")
        page.imageAccessibilityLabel = "⚠️"
        
//        print(isLocation)
        
        page.descriptionText = isLocation ? "Vous avez choisit pour le moment d'afficher les commerces en fonction de votre position" : "Vous avez choisit pour le moment d'afficher les commerces en fonction de leur popularité"
        page.actionButtonTitle = isLocation ? "Trier par popularité" : "Trier par position"
        page.alternativeButtonTitle = "Annuler"
        
        page.isDismissable = true
        
        return page
    }
    
    static func makeIntroFilterPage() -> PageBulletinItem {
        let page = PageBulletinItem(title: "Bienvenue sur WeeClik")
        page.image = #imageLiteral(resourceName: "icon")
        page.imageAccessibilityLabel = "⚠️"
        
        page.descriptionText = "Afin de vous offrir la meilleure expérience possible, préfériez-vous obtenir vos commerces selon votre position ou selon le plus grand nombre de partage ?"
        page.actionButtonTitle = "Ma position"
        page.alternativeButtonTitle = "Nombre de partage"
        
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

    static func makeIntroPage() -> PageBulletinItem {

        let page = PageBulletinItem(title: "Welcome to Instanimal")
        page.image = #imageLiteral(resourceName: "icon")
        page.imageAccessibilityLabel = "⚠️"

        page.descriptionText = "Discover curated images of the best pets in the world."
        page.actionButtonTitle = "Configure"

        page.isDismissable = false

        page.actionHandler = { item in
            item.displayNextItem()
        }

        page.nextItem = makeNotitificationsPage()

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

    static func makeNotitificationsPage() -> PageBulletinItem {

        let page = PageBulletinItem(title: "Push Notifications")
        page.image = #imageLiteral(resourceName: "Certificate_valid_icon")
        page.imageAccessibilityLabel = "Notifications Icon"

        page.descriptionText = "Receive push notifications when new photos of pets are available."
        page.actionButtonTitle = "Subscribe"
        page.alternativeButtonTitle = "Not now"

        page.isDismissable = false

        page.actionHandler = { item in
            item.displayNextItem()
        }

        page.alternativeHandler = { item in
            item.displayNextItem()
        }

        page.nextItem = makeLocationPage()

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

    static func makeLocationPage() -> PageBulletinItem {

        let page = PageBulletinItem(title: "Customize Feed")
        page.image = #imageLiteral(resourceName: "Certificate_valid_icon")
        page.imageAccessibilityLabel = "Location Icon"

        page.descriptionText = "We can use your location to customize the feed. This data will be sent to our servers anonymously. You can update your choice later in the app settings."
        page.actionButtonTitle = "Send location data"
        page.alternativeButtonTitle = "No thanks"

        page.shouldCompactDescriptionText = true
        page.isDismissable = false

        page.actionHandler = { item in
            item.displayNextItem()
        }

        page.alternativeHandler = { item in
            item.displayNextItem()
        }

        page.nextItem = makeCompletionPage()

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

    static func makeCompletionPage() -> PageBulletinItem {

        let page = PageBulletinItem(title: "Setup Completed")
        page.image = #imageLiteral(resourceName: "Certificate_valid_icon")
        page.imageAccessibilityLabel = "Checkmark"
        page.interfaceFactory.tintColor = #colorLiteral(red: 0.2941176471, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        page.interfaceFactory.actionButtonTitleColor = .white

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
