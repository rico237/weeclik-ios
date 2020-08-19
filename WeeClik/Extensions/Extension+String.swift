//
//  Extension+String.swift
//  WeeClik
//
//  Created by Herrick Wolber on 19/08/2020.
//  Copyright © 2020 Herrick Wolber. All rights reserved.
//

import UIKit

extension String {

    // To check text field or String is blank or not
    func isBlank() -> Bool {
        let trimmed = trimmingCharacters(in: CharacterSet.whitespaces)
        return trimmed.isEmpty
    }

    // If only number
    func isAlphanumeric() -> Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }

    private func matches(pattern: String) -> Bool {
        let regex = try! NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive])
        return regex.firstMatch(
            in: self,
            options: [],
            range: NSRange(location: 0, length: utf16.count)) != nil
    }
    // FIXME: Don't accept url without http(s)
    func isValidURL() -> Bool {
        guard let url = self.getURL() else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func getURL() -> URL? {
        guard var url = URL(string: self) else { return nil }
        if url.scheme == nil {
            url = URL(string: "https://\(self)")!
        }
        return url
    }

    // validate Password
    func isValidPassword() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[a-zA-Z_0-9\\-_,;.:#+*?=!§$%&/()@]+$", options: .caseInsensitive)
            if(regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.count)) != nil) {

                if(self.count>=6 && self.count<=20) {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        } catch {
            return false
        }
    }

    // Valid phone
    func isValidPhone() -> Bool {
        let phoneRegex = "^[0-9+]{0,1}[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: self)
    }

    /// Validate email
    ///
    /// - returns: A Boolean value indicating whether an email is valid.
    func isValidEmail() -> Bool {
        let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
        "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" + "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" +
        "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"

        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}

