//
//  PresentationCollectionView.swift
//  BDInteractiveMovementCollectionViewLayout
//
//  Created by 施正宇 on 2019/5/27.
//  Copyright © 2019 施正宇. All rights reserved.
//

import UIKit

class PresentationCollectionView: UICollectionView {
    weak var flowlayout: InteractiveMovementCollectionViewLayout?
    
    override func endInteractiveMovement() {
        super.endInteractiveMovement()
    }
}

