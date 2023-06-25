//
//  pastMonthRidesCell.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 20.05.23.
//


import UIKit

class pastMonthRidesCell: UITableViewCell {
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func layoutSubviews() {
            super.layoutSubviews()

            // Add spacing between cells
            let spacing: CGFloat = 7
            contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: spacing, left: 0, bottom: spacing, right: 0))
        }
}
