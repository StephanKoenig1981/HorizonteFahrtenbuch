//
//  pastMonthRidesCell.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 20.05.23.
//


import UIKit
import Foundation


class pastMonthRidesCell: UITableViewCell {
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var timePercentageLabel: UILabel!
    @IBOutlet weak var distancePercentageLabel: UILabel!
    
    @IBOutlet weak var distancePercentageArrow: UIButton!
    @IBOutlet weak var timePercentageArrow: UIButton!
   
    
    override func layoutSubviews() {
            super.layoutSubviews()

            // Add spacing between cells
            let spacing: CGFloat = 7
            contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: spacing, left: 0, bottom: spacing, right: 0))
        }
}
