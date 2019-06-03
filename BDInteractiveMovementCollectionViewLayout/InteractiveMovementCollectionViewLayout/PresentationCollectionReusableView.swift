//
//  PresentationCollectionReusableView.swift
//  BDInteractiveMovementCollectionViewLayout
//
//  Created by 施正宇 on 2019/5/28.
//  Copyright © 2019 施正宇. All rights reserved.
//

import UIKit

class PresentationCollectionReuseableView: UICollectionReusableView {
    var displayText: String = "defalut" {
        didSet {
            displayLabel.text = self.displayText
        }
    }
    fileprivate lazy var displayLabel: UILabel = {
        let label = UILabel.init(frame:self.bounds)
        label.backgroundColor = UIColor.gray
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(displayLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(displayLabel)
    }
}
