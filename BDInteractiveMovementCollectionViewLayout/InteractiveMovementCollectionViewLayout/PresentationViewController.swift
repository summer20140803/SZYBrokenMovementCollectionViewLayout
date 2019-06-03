//
//  PresentationViewController.swift
//  BDInteractiveMovementCollectionViewLayout
//
//  Created by 施正宇 on 2019/5/27.
//  Copyright © 2019 施正宇. All rights reserved.
//

import UIKit

private let itemCollectionEdgeMargin: CGFloat = 20.0
private let itemLineMargin: CGFloat = 15.0
private let itemHeight: CGFloat = 60.0
private let itemWidth: CGFloat = 60.0
private let sectionHeaderSize: CGSize = CGSize(width: UIScreen.main.bounds.size.width, height: 40)
private let sectionFooterSize: CGSize = CGSize(width: UIScreen.main.bounds.size.width, height: 30)

class PresentationViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var models = ["0", "1", "2", "3", "4", "5", "6", "7", "8"]
    private var skipIndexPaths = [IndexPath(row: 5, section: 0)]
    
    lazy var collectionView: PresentationCollectionView = {
        let flowLayout: InteractiveMovementCollectionViewLayout = InteractiveMovementCollectionViewLayout()
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        flowLayout.minimumLineSpacing = CGFloat(itemLineMargin)
        flowLayout.minimumInteritemSpacing = CGFloat(itemCollectionEdgeMargin)
        flowLayout.sectionInset = UIEdgeInsets(top: CGFloat(itemLineMargin), left: CGFloat(itemCollectionEdgeMargin), bottom: CGFloat(itemLineMargin), right: CGFloat(itemCollectionEdgeMargin))
        
        flowLayout.skipIndexPaths = self.skipIndexPaths
        self.flowLayout = flowLayout
        
        let collectionView = PresentationCollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PresentationCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(PresentationCollectionViewCell.self))
        collectionView.register(PresentationCollectionReuseableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(PresentationCollectionReuseableView.self))
        collectionView.register(PresentationCollectionReuseableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(PresentationCollectionReuseableView.self))
        collectionView.backgroundColor = UIColor.yellow
        collectionView.isScrollEnabled = true
        collectionView.alwaysBounceVertical = true
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handlLongPress(gesture:)))
        collectionView.addGestureRecognizer(longPressGesture)
        collectionView.flowlayout = flowLayout
        
        return collectionView
    }()
    
    var flowLayout: InteractiveMovementCollectionViewLayout?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.view.bounds)
        
        self.collectionView.frame = CGRect(x: 0, y: 100, width: self.view.bounds.size.width, height: 400)
        view.addSubview(self.collectionView)
    }
    
    @objc func handlLongPress(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case UIGestureRecognizerState.began:
            print("start longGesture")
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else { break }
            self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case UIGestureRecognizerState.changed:
            self.collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view))
        case UIGestureRecognizerState.ended:
            self.collectionView.endInteractiveMovement()
        default:
            self.collectionView.cancelInteractiveMovement()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("dataSource updated")
        /// mock datasource
        self.models.append("\(self.models.count)")
        self.collectionView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension PresentationViewController {
    // MARK: DataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.models.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: PresentationCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(PresentationCollectionViewCell.self), for: indexPath) as! PresentationCollectionViewCell
        cell.displayText = "\(self.models[indexPath.row])"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("\(sourceIndexPath.row) insert to \(destinationIndexPath.row)")
        let model = self.models.remove(at: sourceIndexPath.row)
        self.models.insert(model, at: destinationIndexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        return proposedIndexPath
    }
    
    // MARK: Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "action", message: "\(self.models[indexPath.row])", preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "ok", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Flowlayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return sectionHeaderSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return sectionFooterSize
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view: PresentationCollectionReuseableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(PresentationCollectionReuseableView.self), for: indexPath) as! PresentationCollectionReuseableView
        view.displayText = kind
        return view
    }
}
