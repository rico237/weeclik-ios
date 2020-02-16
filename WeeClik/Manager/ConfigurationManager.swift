//
//  ConfigurationManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 13/02/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

final class ConfigurationManager: Decodable {
    
    let target: String
    let api: APIConfiguration
    let endPoints: EndPointsConfiguration
    
    func isDev() -> Bool {
        return target == "DEV"
    }
    
    // MARK: Shared instance
    static let shared: ConfigurationManager = {
        guard let configurationPath = Bundle.main.path(forResource: "configuration", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: configurationPath)) else {
                Log.all.error("configuration.json not found")
                fatalError("configuration.json not found")
        }
        do {
            return try JSONDecoder().decode(ConfigurationManager.self, from: data)
        } catch {
            Log.all.error("configuration.json not found")
            fatalError("configuration.json decoding error")
        }
    }()
}

extension ConfigurationManager {
    struct APIConfiguration: Decodable {
        let baseURL: String
        let appId: String
        let webapp: String
    }
    
    struct EndPointsConfiguration: Decodable {
        let server: String
        let dashboard: String
        let commerce: String
    }
}
