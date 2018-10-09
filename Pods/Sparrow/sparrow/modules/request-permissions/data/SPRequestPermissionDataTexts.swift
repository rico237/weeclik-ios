// The MIT License (MIT)
// Copyright © 2017 Ivan Vorobei (hello@ivanvorobei.by)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

struct SPRequestPermissionData {}

extension SPRequestPermissionData {
    
    struct texts {
        static func title() -> String {
            return "Hello!"
        }
        
        static func subtitile() -> String {
            return "Weeclik a besoin de votre autorisation"
        }
        
        static func advice() -> String {
            return "Afin d'afficher les commerces près de vous."
        }
        
        static func advice_additional() -> String {
            return "Modifiable dans les réglages"
        }
        
        static func enable_camera() -> String {
            return "Camera"
        }
        
        static func enable_photoLibrary() -> String {
            return "Photos/vidéos"
        }
        
        static func enable_notification() -> String {
            return "Notifications"
        }
        
        static func enable_microphone() -> String {
            return "Microphone"
        }
        
        static func enable_calendar() -> String {
            return "Calendrier"
        }
        
        static func enable_location() -> String {
            return "Localisation"
        }
        
        static func enable_contacts() -> String {
            return "Contacts"
        }
        
        static func enable_reminedrs() -> String {
            return "Rappels"
        }
        
        static func swipe_for_hide() -> String {
            return ""
        }
        
        static func cancel() -> String {
            return "Annuler"
        }
        
        static func settings() -> String {
            return "Settings"
        }
        
        static func titleForDenidPermission() -> String {
            return "Important"
        }
        
        static func subtitleForDenidPermission() -> String {
            return "Permission denied. Please, go to Settings and allow permissions"
        }
    }
}
