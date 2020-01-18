//
//  Routers.swift
//  WeeClik
//
//  Created by Herrick Wolber on 05/08/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

import Foundation
import Compass

/// Route to show detail of commerce
struct CommerceRoute: Routable {
    /// Display detail of commerce
    func navigate(to location: Location, from currentController: CurrentController) throws {
        print("Routing location log : \(location)")
        guard let commerceId = location.arguments["commerceId"] else {
            return
        }

        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailCommerceViewController") as! DetailCommerceViewController
        controller.routeCommerceId = commerceId
        currentController.navigationController?.pushViewController(controller, animated: true)
    }
}
