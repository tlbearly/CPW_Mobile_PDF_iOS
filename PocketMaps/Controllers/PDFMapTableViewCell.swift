//
//  MapRowTableViewCell.swift
//  MapViewer
//
//  Purpose: displays one row in the PDF imported maps list
//
//  Created by Tammy Bearly on 4/14/20.
//  Copyright © 2020 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class MapListTableViewCell: UITableViewCell {

    @IBOutlet weak var pdfImage: UIImageView!
    @IBOutlet weak var nameTxt: UILabel!
    @IBOutlet weak var loadingProgress: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
