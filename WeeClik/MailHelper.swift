//
//  MailHelper.swift
//  WeeClik
//
//  Created by Herrick Wolber on 01/06/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit
import Parse
import Alamofire

class MailHelper: NSObject {
    
    func sendRequest(content: String = "Default : No description was given") {
        /* Configure session, choose between:
         * defaultSessionConfiguration
         * ephemeralSessionConfiguration
         * backgroundSessionConfigurationWithIdentifier:
         And set session-wide properties, such as: HTTPAdditionalHeaders,
         HTTPCookieAcceptPolicy, requestCachePolicy or timeoutIntervalForRequest.
         */
        let sessionConfig = URLSessionConfiguration.default
        
        /* Create session, and optionally set a URLSessionDelegate. */
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        /* Create the Request:
         sendErrorMail (POST https://api.eu.mailgun.net/v3/email.herrick-wolber.fr/messages)
         */
        
        guard let URL = URL(string: "https://api.eu.mailgun.net/v3/email.herrick-wolber.fr/messages") else {return}
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        
        // Headers
        
        request.addValue("Basic YXBpOmtleS0zMTEyOWY0ODEyMmU4YmFlMmQyYjE0NjI4ODQ3NzYzZg==", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; charset=utf-8; boundary=__X_PAW_BOUNDARY__", forHTTPHeaderField: "Content-Type")
        
        // Body
        
        let bodyString = "--__X_PAW_BOUNDARY__\r\nContent-Disposition: form-data; name=\"from\"\r\n\r\nExcited User <mailgun@email.herrick-wolber.fr>\r\n--__X_PAW_BOUNDARY__\r\nContent-Disposition: form-data; name=\"to\"\r\n\r\nwolbereric@gmail.com\r\n--__X_PAW_BOUNDARY__\r\nContent-Disposition: form-data; name=\"subject\"\r\n\r\nError in iOS App\r\n--__X_PAW_BOUNDARY__\r\nContent-Disposition: form-data; name=\"text\"\r\n\r\n\(content)\r\n--__X_PAW_BOUNDARY__--\r\n"
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
        
        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("URL Session Task Succeeded: HTTP \(statusCode)")
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    func sendErrorMail() {
        /**
         Error Mail
         post https://api.eu.mailgun.net/v3/email.herrick-wolber.fr/messages
         */
        
        // Add Headers
        let headers = [
            "Content-Type":"multipart/form-data; charset=utf-8; boundary=__X_PAW_BOUNDARY__",
        ]
        
        let parameters: Parameters = ["content":"Une erreur blabla"]
        AF.request("https://api.eu.mailgun.net/v3/email.herrick-wolber.fr/messages", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: HTTPHeaders.init(headers), interceptor: nil).responseJSON { (response) in
                print(response.debugDescription)
        }
        
//        AF.upload(multipartFormData: <#T##MultipartFormData#>, usingThreshold: <#T##UInt64#>, with: <#T##URLRequestConvertible#>, interceptor: <#T##RequestInterceptor?#>)

        
        
        // Fetch Request
//        AF.upload(multipartFormData: { (multipartFormData) in
//            multipartFormData.append("Excited User <mailgun@email.herrick-wolber.fr>".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName :"from")
//            multipartFormData.append("wolbereric@gmail.com".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName :"to")
//            multipartFormData.append("Error in iOS App".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName :"subject")
//            multipartFormData.append("Invalid identifier in payment process".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName :"text")
//        }, to: "https://api.eu.mailgun.net/v3/email.herrick-wolber.fr/messages", method: .post, headers: headers, encodingCompletion: { encodingResult in
//            switch encodingResult {
//            case .success(let upload, _, _):
//                upload.responseJSON { response in
//                    debugPrint(response)
//                }
//            case .failure(let encodingError):
//                print(encodingError)
//            }
//        })
    }
    
    


}
