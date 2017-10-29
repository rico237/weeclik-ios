//
//  LabelUnit.swift
//  Compose
//
//  Created by Bruno Bilescky on 16/10/16.
//  Copyright © 2016 VivaReal. All rights reserved.
//

import UIKit

/// Sample unit, which display a text inside a UILabel
public struct LabelUnit: ComposingUnit, TwoStepDisplayUnit {

    typealias Cell = ComposingUnitCollectionViewCell<UILabel>
    
    let numberOfLines: Int
    let backgroundColor: UIColor
    let attributedText: NSAttributedString
    private let maxHeight: CGFloat?
    public let insets: UIEdgeInsets
    public let identifier: String
    
    /// Common Init
    ///
    /// - parameter id:            this unit identifier
    /// - parameter text:          text that will be displayed
    /// - parameter font:          font to use
    /// - parameter color:         text color
    /// - parameter background:    cell background color
    /// - parameter numberOfLines: number of lines to use
    public init(id: String, text: String?, font: UIFont, color: UIColor, backgroundColor: UIColor, maxHeight: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets(horizontal: 16), numberOfLines: Int = 0) {
        let attributes = [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: color]
        let attributed = NSAttributedString(string: text ?? "", attributes: attributes)
        self.init(id: id, text: attributed, backgroundColor: backgroundColor, maxHeight: maxHeight, insets: insets, numberOfLines: numberOfLines)
        
    }
    
    public init(id: String, text: NSAttributedString, backgroundColor: UIColor, maxHeight: CGFloat? = nil, insets: UIEdgeInsets = UIEdgeInsets(horizontal: 16), numberOfLines: Int = 0) {
        self.identifier = id
        self.maxHeight = maxHeight
        self.insets = insets
        self.backgroundColor = backgroundColor
        self.numberOfLines = numberOfLines
        self.attributedText = text
    }
    
    /// Configure this UILabel with the given attributes
    ///
    /// - parameter view: the label to be configured
    public func configure(view: UIView) {
        guard let cell = view as? Cell else { return }
        cell.insets = self.insets
        cell.innerView.numberOfLines = self.numberOfLines
        cell.backgroundColor = backgroundColor
    }
    
    /// Called just before the view is displayed. Used to set the text that will be displayed
    ///
    /// - parameter view: label to configure
    public func beforeDisplay(view: UIView) {
        guard let cell = view as? Cell else { return }
        cell.innerView.attributedText = self.attributedText
    }
    
    /// Dynamic height based on the font, number of lines and text
    public var heightUnit: DimensionUnit {
        return DimensionUnit { size in
            let options: NSStringDrawingOptions = self.numberOfLines != 1 ? .usesLineFragmentOrigin : []
            let fitRect = self.attributedText.boundingRect(with: size, options: options, context: nil)
            let textHeight = round(fitRect.height) + self.insets.verticalInsets + 2
            if let maxHeight = self.maxHeight {
                return min(maxHeight, textHeight)
            }
            else {
                return textHeight
            }
        }
    }
    
    /// Dynamic width based on the font, number of lines and text
    public var widthUnit: DimensionUnit {
        return 0
    }
    
    /// Cell reuse identifier
    public func reuseIdentifier() -> String {
        return Cell.identifier()
    }
    
    /// Register inside collectionView
    public func register(in collectionView: UICollectionView) {
        Cell.register(in: collectionView)
    }
    
}
