//
//  Extensions.swift
//  WeeClik
//
//  Created by Herrick Wolber on 02/04/2018.
//  Copyright © 2018 Herrick Wolber. All rights reserved.
//

/**
 String + Array + Collection + Error + TimeInterval + UIColor + UIDevice + UIImage + UIView + Double +
 UserDefaults + CALayer + UIWindow + UIFont
 */

import UIKit

extension Array {
    // Get safe element from Array (no index out of range error)
    subscript(safe index: Index) -> Element? {
        let isValidIndex = index >= 0 && index < count
        return isValidIndex ? self[index] : nil
    }
}

extension Collection {
    // Get safe element from collection (no index out of range error)
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
    var desc: String { return (self as NSError).description }
    var debug: String {
        return """
        
            Error description :
                Code: \(self.code)
                Description: \(self.localizedDescription)
                Desc: \(self.desc)
                Domain: \(self.domain)
        
        """
    }
}

extension TimeInterval {
    // builds string in app's labels format 00:00
    func stringFormatted() -> String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

}

extension UIColor {
    convenience init(hexFromString: String, alpha: CGFloat = 1.0) {
        var cString: String = hexFromString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgbValue: UInt64 = 10066329 //color #999999 if string has wrong format

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) == 6) {
            Scanner(string: cString).scanHexInt64(&rgbValue)
        }

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension UIDevice {
    static var isIphoneXOLD: Bool {
        var modelIdentifier = ""
        if isSimulator {
            modelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
        } else {
            var size = 0
            sysctlbyname("hw.machine", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.machine", &machine, &size, nil, 0)
            modelIdentifier = String(cString: machine)
        }
        Log.console.verbose("Model identiier : \(modelIdentifier)")
        return modelIdentifier == "iPhone10,3" || modelIdentifier == "iPhone10,6" || modelIdentifier.starts(with: "iPhone11,") || modelIdentifier.starts(with: "iPhone12,")
    }
    
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    static var isIphoneX: Bool {
        if #available(iOS 11.0, *), isIphone {
            if isLandscape {
                if let leftPadding = UIApplication.shared.windows.first?.safeAreaInsets.left, leftPadding > 0 {
                    return true
                }
                if let rightPadding = UIApplication.shared.windows.first?.safeAreaInsets.right, rightPadding > 0 {
                    return true
                }
            } else {
                if let topPadding = UIApplication.shared.windows.first?.safeAreaInsets.top, topPadding > 0 {
                    return true
                }
                if let bottomPadding = UIApplication.shared.windows.first?.safeAreaInsets.bottom, bottomPadding > 0 {
                    return true
                }
            }
        }
        return false
    }

    static var isIphone: Bool {
        return self.current.userInterfaceIdiom == .phone
    }
    
    static var isLandscape: Bool {
        if #available(iOS 13.0, *) {
            return self.current.orientation.isLandscape
                || UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape ?? false
        } else {
            return self.current.orientation.isLandscape
        }
    }

    static var isPortrait: Bool {
        if #available(iOS 13.0, *) {
            return self.current.orientation.isPortrait
                || UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isPortrait ?? false
        } else {
            return self.current.orientation.isPortrait
        }
    }
}

extension UIApplication {
    static var isDeviceWithSafeArea: Bool {
        if #available(iOS 11.0, *) {
            if let bottomPadding = shared.windows.first?.safeAreaInsets.bottom,
                bottomPadding > 0 {
                return true
            }
        }
        return false
    }
}

extension UIImage {
    func isEqualToImage(image: UIImage) -> Bool {
        let data1: Data = self.jpegData(compressionQuality: 1)!
        let data2: Data = image.jpegData(compressionQuality: 1)!
        return data1 == data2
    }

    func isEqualToData(data: Data) -> Bool {
        return self.jpegData(compressionQuality: 1) == data
    }

    public func rounded(radius: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

extension UIView {
    func setCardView(view: UIView) {
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 3
    }
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

    func anchor (top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?, paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat, enableInsets: Bool) {
        var topInset = CGFloat(0)
        var bottomInset = CGFloat(0)

        if enableInsets {
            let insets = self.safeAreaInsets
            topInset = insets.top
            bottomInset = insets.bottom

            Log.console.verbose("Top: \(topInset)")
            Log.console.verbose("bottom: \(bottomInset)")
        }

        translatesAutoresizingMaskIntoConstraints = false

        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop+topInset).isActive = true
        }
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom-bottomInset).isActive = true
        }
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }

    }

}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return Darwin.round(self * divisor) / divisor
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}

extension CALayer {
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        let border = CALayer()

        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: thickness)
        case UIRectEdge.bottom:
            border.frame = CGRect.init(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
        case UIRectEdge.left:
            border.frame = CGRect.init(x: 0, y: 0, width: thickness, height: frame.height)
        case UIRectEdge.right:
            border.frame = CGRect.init(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
        default:
            break
        }

        border.backgroundColor = color.cgColor
        self.addSublayer(border)
    }
}

extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(self.rootViewController)
    }

    static func getVisibleViewControllerFrom(_ viewController: UIViewController?) -> UIViewController? {
        if let viewController = viewController as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(viewController.visibleViewController)
        } else if let viewController = viewController as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(viewController.selectedViewController)
        } else {
            if let viewController = viewController?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(viewController)
            } else {
                return viewController
            }
        }
    }
}

extension UIButton {
    func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
        ) {
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: contentPadding.left,
            bottom: contentPadding.bottom,
            right: contentPadding.right + imageTitlePadding
        )
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
}

extension UIFont {

    public enum OpenSansType: String {
        case extraboldItalic = "-ExtraboldItalic"
        case semiboldItalic = "-SemiboldItalic"
        case semibold = "-Semibold"
        case regular = ""
        case lightItalic = "Light-Italic"
        case light = "-Light"
        case italic = "-Italic"
        case extraBold = "-Extrabold"
        case boldItalic = "-BoldItalic"
        case bold = "-Bold"
    }

    static func openSans(_ type: OpenSansType = .regular, size: CGFloat = UIFont.systemFontSize) -> UIFont {
        return UIFont(name: "OpenSans\(type.rawValue)", size: size)!
    }

    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }

}

extension UITextView {
    // this will be reached if the text is nil (unlikely)
    // or if the text only contains white spaces
    // or no text at all
    func validate() -> Bool {
        guard let text = self.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }
}
