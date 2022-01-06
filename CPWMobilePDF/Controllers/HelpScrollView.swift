//
//  HelpScrollView.swift
//  CPWMobilePDF
//
//  Help Template: scrolling logo, title, and text block
//
//
//  Created by Tammy Bearly on 1/5/22.
//  Copyright © 2022 Colorado Parks and Wildlife. All rights reserved.
//

import UIKit

class HelpScrollView: UIScrollView {
    init(_ scrollView: UIScrollView, view: UIView, helpTitleStr: String, helpTextStr: String) {
        super.init(frame: .zero)
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        // Logo
        let viewForImg = UIView()
        let imgView = UIImageView(image: UIImage(named: "icon"))
        let imgSize:CGFloat = 140.0
        imgView.layer.borderColor = UIColor.lightGray.cgColor
        imgView.layer.borderWidth = 3
        viewForImg.layer.shadowColor = UIColor.gray.cgColor
        viewForImg.layer.shadowOpacity = 0.7
        viewForImg.layer.shadowOffset = .zero
        viewForImg.layer.shadowRadius = 5
        viewForImg.layer.cornerRadius = imgSize / 2.0 // round
        viewForImg.clipsToBounds = true
        viewForImg.layer.masksToBounds = false
        imgView.layer.cornerRadius = imgSize / 2.0
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        viewForImg.addSubview(imgView)
        contentView.addSubview(viewForImg)
        imgView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: imgSize).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: imgSize).isActive = true
        imgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true
        
        // Title
        let helpTitle = UILabel()
        helpTitle.text = helpTitleStr
        helpTitle.font = UIFont.systemFont(ofSize: 24)
        helpTitle.sizeToFit()
        helpTitle.numberOfLines = 0
        helpTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpTitle)
        // Set its constraint to display it on screen
        helpTitle.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 4/5).isActive = true
        helpTitle.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 10).isActive = true
        helpTitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        let helpText = UILabel()
        helpText.text = helpTextStr
        helpText.numberOfLines = 0
        helpText.sizeToFit()
        helpText.font = UIFont.systemFont(ofSize: 17)
        helpText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpText)
        helpText.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 4/5).isActive = true
        helpText.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        helpText.topAnchor.constraint(equalTo: helpTitle.bottomAnchor, constant: 10).isActive = true
        helpText.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 10).isActive = true
        //helpText.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
