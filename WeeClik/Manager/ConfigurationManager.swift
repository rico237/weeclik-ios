//
//  ConfigurationManager.swift
//  WeeClik
//
//  Created by Herrick Wolber on 13/02/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

final class ConfigurationManager: Decodable {
    
    // MARK: Shared instance
    static let instance: ConfigurationManager = {
        guard let configurationPath = Bundle.main.path(forResource: "configuration", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: configurationPath)) else {
                Log.all.error("configuration.json not found")
                fatalError("configuration.json not found")
        }
        do {
            return try JSONDecoder().decode(JSONConfigurationManager.self, from: data)
        } catch {
            Log.all.error("configuration.json not found")
            fatalError("configuration.json decoding error")
        }
    }()
}
