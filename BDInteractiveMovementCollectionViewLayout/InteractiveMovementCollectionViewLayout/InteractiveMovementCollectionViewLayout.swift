//
//  InteractiveMovementCollectionViewLayout.swift
//  BDInteractiveMovementCollectionViewLayout
//
//  Created by slientCat on 2019/5/26.
//  Copyright © 2019 slientCat. All rights reserved.
//

import UIKit

open class InteractiveMovementCollectionViewLayout: UICollectionViewFlowLayout {
    /// 在正常的 flowlayout 排列基础上，在拖拽移动 item 的同时可以选择空出的位置的 indexPaths
    /// 支持横竖屏切换，支持增加 section 头部和尾部，但目前只支持单 section
    public var skipIndexPaths: [IndexPath] = [] {
        didSet {
            setUpdateAttributesIfNeeded = true
        }
    }

    /// 可以标记这个属性为 true 来强制 layout 进行布局更新
    public var setUpdateAttributesIfNeeded: Bool = false

    fileprivate var layoutAttributeArray: [[UICollectionViewLayoutAttributes]] = [[]]
    fileprivate var reusableHeaderAttributeArray: [UICollectionViewLayoutAttributes] = []
    fileprivate var reusableFooterAttributeArray: [UICollectionViewLayoutAttributes] = []
    fileprivate var currentSkipIndex: Int = 0
    fileprivate var cachedContentSize: CGSize = CGSize.zero
    fileprivate var cachedLayoutHash = NSNotFound
}

extension InteractiveMovementCollectionViewLayout {
    /// 优化性能
    fileprivate struct RespondFieldFlags {
        var sizeForItemImp: Bool = false
        var insetForSectionImp: Bool = false
        var minimumLineSpacingForSectionImp: Bool = false
        var minimumInteritemSpacingForSectionImp: Bool = false
        var referenceSizeForHeaderInSectionImp: Bool = false
        var referenceSizeForFooterInSectionImp: Bool = false
    }

    /// must override
    open override var collectionViewContentSize: CGSize {
        return self.cachedContentSize
    }

    open override func prepare() {
        super.prepare()

        guard let collectionView = self.collectionView else { return }
        let dataSource: UICollectionViewDataSource = collectionView.dataSource!

        // TODO: 支持多 section && cachedhash 策略更新
        /// 暂时先考虑 item count 的变更会触发布局更新，或者可以通过设置 `setNeedUpdateAttributesIfNeeded` 强制触发
        let newItemCounts = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

        if setUpdateAttributesIfNeeded || (newItemCounts != cachedLayoutHash) {
            cleanLayoutAttributesCache()
            updateLayoutAttributesCache()
            setUpdateAttributesIfNeeded = false
        }
    }

    /// 设置 超过 collectionView 的 bounds 时会使当前的 layout 失效，使其重新获取布局信息
    open override func shouldInvalidateLayout(forBoundsChange _: CGRect) -> Bool {
        return true
    }

    /// 告诉 collectionViewLayout 应该以怎样的布局落位(相当于提供 IndexPath 到 UICollectionViewLayoutAttributes 的映射关系)
    /// 但是此方法不会 collectionView 刚显示时触发，会在拖拽移动和拖拽结束时被 layout 触发询问
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributeArray[indexPath.section][indexPath.row]
    }

    /// 告诉 collectionViewLayout 应该以怎样的布局落位(相当于提供 IndexPath 到 UICollectionViewLayoutAttributes 的映射关系)
    /// 但是此方法不会 collectionView 刚显示时触发，会在拖拽移动和拖拽结束时被 layout 触发询问
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == UICollectionView.elementKindSectionHeader {
            return reusableHeaderAttributeArray[indexPath.section]
        } else if elementKind == UICollectionView.elementKindSectionFooter {
            return reusableFooterAttributeArray[indexPath.section]
        } else {
            return nil
        }
    }

    /// 告诉 collectionViewLayout 当前的可视区域的 items 应该如何落位(相当于提供可视区域内的 items 的 UICollectionViewLayoutAttributes信息)
    /// 此方法会在 collectionView 刚显示、滑动时和拖拽移动item时触发，但是不会在拖拽结束时(即拖拽手势松开后)被 layout 询问
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // TODO: 支持多 section
        return layoutAttributeArray[0].filter { $0.frame.intersects(rect) }
            + reusableHeaderAttributeArray.filter { $0.frame.intersects(rect) }
            + reusableFooterAttributeArray.filter { $0.frame.intersects(rect) }
    }

    /// 更新所有 items 对应的自定义的布局属性 (UICollectionViewLayoutAttributes) 并缓存下来
    fileprivate func updateLayoutAttributesCache() {
        let collectionView = self.collectionView!
        let delegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout

        let respondFlags: RespondFieldFlags = setRespondBitFieldFlags(delegate: delegate)

        let itemSize = respondFlags.sizeForItemImp ?
            delegate!.collectionView!(collectionView, layout: self, sizeForItemAt: IndexPath(row: 0, section: 0)) :
            self.itemSize
        
        let sectionInset = respondFlags.insetForSectionImp ?
            delegate!.collectionView!(collectionView, layout: self, insetForSectionAt: 0) :
            self.sectionInset
        
        let minimumLineSpacing = respondFlags.minimumLineSpacingForSectionImp ?
            delegate!.collectionView!(collectionView, layout: self, minimumLineSpacingForSectionAt: 0) :
            self.minimumLineSpacing
        
        let minimumInteritemSpacing = respondFlags.minimumInteritemSpacingForSectionImp ?
            delegate!.collectionView!(collectionView, layout: self, minimumInteritemSpacingForSectionAt: 0) :
            self.minimumInteritemSpacing

        let sectionCount = collectionView.numberOfSections
        let containerWidth = collectionView.bounds.size.width

        let maxItemSizeForOneLine: Int = getMaxItemSizeForOneRow(containerWidth: containerWidth,
                                                                 leftInset: sectionInset.left,
                                                                 rightInset: sectionInset.right,
                                                                 minimumInteritemSpacing: minimumInteritemSpacing,
                                                                 itemWidth: itemSize.width)
        
        let realInteritemSpacing = getRealInteritemSpacing(containerWidth: containerWidth,
                                                           itemCount: maxItemSizeForOneLine,
                                                           leftInset: sectionInset.left,
                                                           rightInset: sectionInset.right,
                                                           itemWidth: itemSize.width)

        cachedContentSize = CGSize(width: collectionView.bounds.size.width, height: 0)

        for i in 0 ..< sectionCount {
            /// must copy
            if let headerAttr: UICollectionViewLayoutAttributes = super.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(index: i))?.copy() as? UICollectionViewLayoutAttributes {
                reusableHeaderAttributeArray.append(headerAttr)
            } else {
                let emptyAttr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(index: i))
                reusableHeaderAttributeArray.append(emptyAttr)
            }

            let rowCount = collectionView.numberOfItems(inSection: i)

            for j in 0 ..< rowCount {
                let indexPath = IndexPath(row: j, section: i)
                /// must copy
                let currentAttr: UICollectionViewLayoutAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes ?? UICollectionViewLayoutAttributes(forCellWith: indexPath)

                if skipIndexPaths.contains(indexPath) {
                    currentSkipIndex += 1
                }

                let finalLocation = nextAvailableLocation(withIndexPath: indexPath,
                                                          maxItemCountForOneRow: maxItemSizeForOneLine,
                                                          skipIndex: currentSkipIndex,
                                                          leftInset: sectionInset.left,
                                                          interitemSpacing: realInteritemSpacing,
                                                          lineSpacing: minimumLineSpacing,
                                                          itemSize: itemSize)

                currentAttr.frame = finalLocation
                // TODO: 支持多 section
                layoutAttributeArray[0].append(currentAttr)
            }

            /// must copy
            if let footerAttr: UICollectionViewLayoutAttributes = super.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: IndexPath(index: i))?.copy() as? UICollectionViewLayoutAttributes {
                // TODO: 支持多 section
                if let lastItemAttr = self.layoutAttributeArray[0].last {
                    footerAttr.frame.origin.y = lastItemAttr.frame.origin.y + lastItemAttr.bounds.height + minimumLineSpacing
                } else {
                    footerAttr.frame.origin.y = reusableHeaderAttributeArray[i].frame.origin.y + reusableHeaderAttributeArray[i].bounds.height
                }
                reusableFooterAttributeArray.append(footerAttr)
            } else {
                let emptyAttr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: IndexPath(index: i))
                reusableFooterAttributeArray.append(emptyAttr)
            }
        }

        let zero: CGFloat = 0
        let lastHeaderBottom = (reusableHeaderAttributeArray.last?.frame.origin.y ?? zero) + (reusableHeaderAttributeArray.last?.bounds.size.height ?? zero)
        let lastItemBottom = (layoutAttributeArray.last?.last?.frame.origin.y ?? zero) + (layoutAttributeArray.last?.last?.bounds.size.height ?? zero) + sectionInset.bottom
        let lastFooterBottom = (reusableFooterAttributeArray.last?.frame.origin.y ?? zero) + (reusableFooterAttributeArray.last?.bounds.size.height ?? zero)
        cachedContentSize.height = max(lastHeaderBottom, lastItemBottom, lastFooterBottom)

        /// update cached layout hash
        // TODO: 支持多 section && cachedhash 策略更新
        cachedLayoutHash = layoutAttributeArray.first!.count
    }

    /// 清空自定义布局缓存
    fileprivate func cleanLayoutAttributesCache() {
        layoutAttributeArray = [[]]
        reusableHeaderAttributeArray = []
        reusableFooterAttributeArray = []
        currentSkipIndex = 0
        cachedContentSize = CGSize.zero
    }

    fileprivate func getMaxItemSizeForOneRow(containerWidth: CGFloat,
                                             leftInset: CGFloat,
                                             rightInset: CGFloat,
                                             minimumInteritemSpacing: CGFloat,
                                             itemWidth: CGFloat) -> Int {
        
        return Int((containerWidth - leftInset - rightInset + minimumInteritemSpacing) / (itemWidth + minimumInteritemSpacing))
    }

    fileprivate func getRealInteritemSpacing(containerWidth: CGFloat,
                                             itemCount: Int,
                                             leftInset: CGFloat,
                                             rightInset: CGFloat,
                                             itemWidth: CGFloat) -> CGFloat {
        
        return (containerWidth - CGFloat(itemCount) * itemWidth - leftInset - rightInset) / CGFloat(itemCount - 1)
    }

    fileprivate func nextAvailableLocation(withIndexPath currentNormalIndexPath: IndexPath,
                                           maxItemCountForOneRow: Int,
                                           skipIndex: Int,
                                           leftInset: CGFloat,
                                           interitemSpacing: CGFloat,
                                           lineSpacing: CGFloat,
                                           itemSize: CGSize) -> CGRect {
        
        let normallocation = normalLocation(withIndexPath: currentNormalIndexPath,
                                            maxItemCountForOneRow: maxItemCountForOneRow,
                                            leftInset: leftInset,
                                            interitemSpacing: interitemSpacing,
                                            lineSpacing: lineSpacing,
                                            itemSize: itemSize)

        let shouldSwitchToBelowtRow = (currentNormalIndexPath.row % maxItemCountForOneRow + skipIndex) > (maxItemCountForOneRow - 1)
        var availableLocation: CGRect = normallocation

        if shouldSwitchToBelowtRow {
            let skipRowCount = (currentNormalIndexPath.row % maxItemCountForOneRow + skipIndex) / maxItemCountForOneRow
            let rowIndex = (currentNormalIndexPath.row + skipIndex) % maxItemCountForOneRow
            availableLocation.origin.x = leftInset + CGFloat(rowIndex) * (itemSize.width + interitemSpacing)
            availableLocation.origin.y += (CGFloat(skipRowCount) * (itemSize.height + lineSpacing))
        } else {
            let skipCount: CGFloat = CGFloat(skipIndex)
            availableLocation.origin.x += skipCount * (itemSize.width + interitemSpacing)
        }
        return availableLocation
    }

    fileprivate func normalLocation(withIndexPath indexPath: IndexPath,
                                    maxItemCountForOneRow _: Int,
                                    leftInset _: CGFloat,
                                    interitemSpacing _: CGFloat,
                                    lineSpacing _: CGFloat,
                                    itemSize _: CGSize) -> CGRect {
        
        return super.layoutAttributesForItem(at: indexPath)!.frame
    }

    fileprivate func setRespondBitFieldFlags(delegate: UICollectionViewDelegateFlowLayout?) -> RespondFieldFlags {
        var flags: RespondFieldFlags = RespondFieldFlags()
        guard delegate != nil else { return flags }

        if delegate!.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAt:))) { flags.sizeForItemImp = true }
        if delegate!.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:insetForSectionAt:))) { flags.insetForSectionImp = true }
        if delegate!.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:minimumLineSpacingForSectionAt:))) { flags.minimumLineSpacingForSectionImp = true }
        if delegate!.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:minimumInteritemSpacingForSectionAt:))) { flags.minimumInteritemSpacingForSectionImp = true }
        if delegate!.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForHeaderInSection:))) { flags.referenceSizeForHeaderInSectionImp = true }
        if delegate!.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:referenceSizeForFooterInSection:))) { flags.referenceSizeForFooterInSectionImp = true }

        return flags
    }
}
