//
//  FontHelper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 18/06/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit

class FontHelper: NSObject {
    // Get the Scaled version of your UIFont.
    ///
    /// - Parameters:
    ///   - name: Name of the UIFont whose scaled version you wish to obtain.
    ///   - textStyle: The text style for your font, i.e Body, Title etc...
    /// - Returns: The scaled UIFont version with the given textStyle
    @available(iOS 11.0, *)
    static func getScaledFont(forFont name: String, textStyle: UIFont.TextStyle) -> UIFont {
        
        /// Uncomment the code below to check all the available fonts and have them printed in the console to double check the font name with existing fonts 😉
        
        /*for family: String in UIFont.familyNames
         {
         print("\(family)")
         for names: String in UIFont.fontNames(forFamilyName: family)
         {
         print("== \(names)")
         }
         }*/
        
        let userFont =  UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let pointSize = userFont.pointSize
        guard let customFont = UIFont(name: name, size: pointSize) else {
            fatalError("""
                Failed to load the "\(name)" font.
                Make sure the font file is included in the project and the font name is spelled correctly.
                """
            )
        }
        return UIFontMetrics.default.scaledFont(for: customFont)
    }
}
