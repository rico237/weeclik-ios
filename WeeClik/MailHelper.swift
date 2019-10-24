//
//  MailHelper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 01/06/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import Alamofire

final class MailHelper {
    /**
     Method called to send amil to admins when an error occurs in app.
     
     Not Functioning for now
     */
    static func sendErrorMail(content: String = "Default : No description was given".localized()) {
        /**
         Error Mail
         post https://api.eu.mailgun.net/v3/email.herrick-wolber.fr/messages
         */

        // Add Headers
        let headers = [
            "Content-Type": "multipart/form-data; charset=utf-8; boundary=__X_PAW_BOUNDARY__"
        ]

        let parameters: Parameters = ["content": content.localized()]
        // FIXME: Needs to be tested and corrected ASAP
        AF.request("https://api.eu.mailgun.net/v3/email.herrick-wolber.fr/messages", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: HTTPHeaders.init(headers), interceptor: nil).responseJSON { (response) in
                print(response.debugDescription)
        }
    }
}
