//
//  PresentationCollectionViewCell.swift
//  BDInteractiveMovementCollectionViewLayout
//
//  Created by 施正宇 on 2019/5/27.
//  Copyright © 2019 施正宇. All rights reserved.
//

import UIKit


class PresentationCollectionViewCell: UICollectionViewCell {
    var displayText: String = "defalut" {
        didSet {
            displayLabel.text = self.displayText
        }
    }
    fileprivate lazy var displayLabel: UILabel = {
        let label = UILabel.init(frame:self.bounds)
        label.backgroundColor = UIColor.green
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(displayLabel)
        self.contentView.layer.cornerRadius = frame.size.width / 2
        self.contentView.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
