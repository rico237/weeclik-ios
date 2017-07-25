//
//  ComposingCollectionView.swift
//  Compose
//
//  Created by Bruno Bilescky on 04/10/16.
//  Copyright © 2016 VivaReal. All rights reserved.
//

import UIKit

/// CollectionView used to display units.
@IBDesignable
public class ComposingCollectionView: UICollectionView, ComposingContainer {

    /// Direction to stack units inside this collectionView
    public var direction: ComposingContainerDirection {
        get {
            return composeDelegate.direction
        }
        set {
            if composeDelegate.direction != newValue {
                composeDelegate.direction = newValue
                self.performBatchUpdates({ 
                    (self.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = newValue.collectionDirection
                })
                self.updateBounces()
            }
        }
    }
    
    /// Current state. On each update here we will use each's unit identifier and add/remove/update cell with animation
    public var state: [ComposingUnit] = [] {
        didSet {
            let identifiers = state.map { unit in
                return unit.identifier
            }
            stateChangeDiff.updateSource(with: identifiers) { [unowned self] in
                self.internalSource.state = self.state
            }
        }
    }
    
    /// Inset applied to each section in the collectionView
    public var sectionInset: UIEdgeInsets {
        get {
            precondition(self.collectionViewLayout is UICollectionViewFlowLayout, "Only works for UICollectionViewFlowLayout")
            return (self.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
        }
        set {
            precondition(self.collectionViewLayout is UICollectionViewFlowLayout, "Only works for UICollectionViewFlowLayout")
            (self.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset = newValue
        }
    }
    
    /// Space applied between items in the collection
    public var itemSpace: CGFloat {
        get {
            precondition(self.collectionViewLayout is UICollectionViewFlowLayout, "Only works for UICollectionViewFlowLayout")
            return (self.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0.0
        }
        set {
            precondition(self.collectionViewLayout is UICollectionViewFlowLayout, "Only works for UICollectionViewFlowLayout")
            (self.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing = newValue
        }
    }
    
    /// Space applied between lines in the collectionView
    public var lineSpace: CGFloat {
        get {
            precondition(self.collectionViewLayout is UICollectionViewFlowLayout, "Only works for UICollectionViewFlowLayout")
            return (self.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 0.0
        }
        set {
            precondition(self.collectionViewLayout is UICollectionViewFlowLayout, "Only works for UICollectionViewFlowLayout")
            (self.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing = newValue
        }
    }
    
    public var scrollDidChangeCallback: ((CGFloat)-> Void)? {
        get {
            return composeDelegate.scrollDidChangeCallback
        }
        set {
            composeDelegate.scrollDidChangeCallback = newValue
        }
    }
    
    private let internalSource = ComposingDataSource(initialState: [])
    
    private lazy var composeDataSource: ComposingCollectionViewDataSource = ComposingCollectionViewDataSource(with: self.internalSource)
    private lazy var composeDelegate: ComposingCollectionViewDelegate = ComposingCollectionViewDelegate(with: self.internalSource)
    
    private lazy var stateChangeDiff: CollectionViewDiffCalculator<String> = {
        let diff = CollectionViewDiffCalculator<String>(collectionView: self)
        diff.finishReorderingCallback = { set in
            self.didFinishReorderingItems(changedSet: set)
        }
        return diff
    }()
    
    /// Callback that will be invoked everytime the collection view finished updating it's state
    public var didFinishUpdateStateCallback: (()-> Void)?
    
    /// Convenience init that uses .zero frame and default layout
    public convenience init() {
        self.init(frame: .zero)
    }
    
    /// Convenience init that uses the default layout
    ///
    /// - parameter frame: initial view frame
    public convenience init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        self.init(frame: frame, collectionViewLayout: layout)
    }
    
    /// Default init
    ///
    /// - parameter frame:  initial view frame
    /// - parameter layout: initial view layout
    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }

    /// Init that unwrap from Interface builder. Will override the view layout to the default type
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let layout = UICollectionViewFlowLayout()
        self.collectionViewLayout = layout
        commonInit()
    }
    
    
    /// Return the indexPath for this unit if it is inside the collectionView state
    ///
    /// - Parameter unit: the unit to find the index
    /// - Returns: an optional IndexPath, in case the unit is inside the collectionView state
    public func indexPath(for unit: ComposingUnit)-> IndexPath? {
        return self.composeDataSource.indexPath(for: unit)
    }
    
    
    /// Scroll to a specific unit, with a given position, and animated
    ///
    /// - Parameters:
    ///   - unit: the unit to scroll to
    ///   - scrollPosition: the desired position of the unit
    ///   - animated: should this be animated
    public func scroll(to unit: ComposingUnit, at scrollPosition: UICollectionViewScrollPosition, animated: Bool = true) {
        guard let indexPath = self.indexPath(for: unit) else { return }
        self.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }
    
    private func commonInit() {
        self.dataSource = composeDataSource
        self.delegate = composeDelegate
        self.updateBounces()
    }
    
    private func updateBounces() {
        self.alwaysBounceVertical = direction.isVertical
        self.alwaysBounceHorizontal = direction.isHorizontal
    }

    private func didFinishReorderingItems(changedSet: Set<Int>) {
        let cellsWithIndexPath: [(UICollectionViewCell, Int)] = self.visibleCells.flatMap { cell in
            guard let indexPath = self.indexPath(for: cell), !changedSet.contains(indexPath.row) else { return nil }
            return (cell, indexPath.item)
        }
        let cellsWithUnits: [(UICollectionViewCell, ComposingUnit)] = cellsWithIndexPath.flatMap { (cell, index) in
            return (cell, self.internalSource[index])
        }
        cellsWithUnits.forEach { (cell, unit) in
            unit.configure(view: cell)
        }
        self.didFinishUpdateStateCallback?()
    }
    
    public override func layoutSubviews() {
        UIView.performWithoutAnimation { 
            super.layoutSubviews()
        }
    }
    
}
