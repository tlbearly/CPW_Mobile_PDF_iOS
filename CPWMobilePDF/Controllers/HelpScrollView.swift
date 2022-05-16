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
    let contentView:UIView = UIView()
    var bottom_anchor:NSLayoutYAxisAnchor = NSLayoutYAxisAnchor()
    var elem = UIView()
    
    init(_ scrollView: UIScrollView, view: UIView) {
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        bottom_anchor = contentView.topAnchor
    }
    
    public func addLogo(){
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
        self.bottom_anchor = imgView.bottomAnchor
    }
    
    public func addTitle(title: String,size:CGFloat=24.0,bold:Bool=false,underline:Bool=false) {
        let helpTitle = UILabel()
        helpTitle.text = title
        if (bold){
            helpTitle.font = UIFont.boldSystemFont(ofSize: size)
        }else{
            helpTitle.font = UIFont.systemFont(ofSize: size)
        }
        helpTitle.sizeToFit()
        if (underline){
            let textRange = NSRange(location: 0, length: title.count)
            let attributedText = NSMutableAttributedString(string: title)
            attributedText.addAttribute(.underlineStyle,
                                        value: NSUnderlineStyle.single.rawValue,
                                        range: textRange)
            helpTitle.attributedText = attributedText
        }
        helpTitle.numberOfLines = 0
        helpTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpTitle)
        // Set its constraint to display it on screen
        //helpTitle.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 4/5).isActive = true
        helpTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        helpTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        helpTitle.topAnchor.constraint(equalTo: bottom_anchor, constant: 30).isActive = true
        //helpTitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        elem = helpTitle
        bottom_anchor = helpTitle.bottomAnchor
    }
    
    public func addText(text: String) {
        // text is the text block to add
        // topText is the UILabel element just above this
        let helpText = UILabel()
        helpText.text = text
        helpText.numberOfLines = 0
        helpText.sizeToFit()
        helpText.font = UIFont.systemFont(ofSize: 17)
        helpText.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(helpText)
        helpText.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        helpText.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        helpText.topAnchor.constraint(equalTo: bottom_anchor, constant: 10).isActive = true
        elem = helpText
        bottom_anchor = helpText.bottomAnchor
    }
    
    public func addImg(img: String, x: CGFloat, y:CGFloat, borderWidth: CGFloat = 3.0){
        let imgView = UIImageView(image: UIImage(named: img))
        imgView.layer.borderColor = UIColor.lightGray.cgColor
        imgView.layer.borderWidth = borderWidth
        imgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imgView)
        imgView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: x).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: y).isActive = true
        imgView.topAnchor.constraint(equalTo: bottom_anchor, constant: 20).isActive = true
        elem = imgView
        bottom_anchor = imgView.bottomAnchor
    }
    
    public func addButton(text: String) -> PrimaryUIButton {
        let btn = PrimaryUIButton()
        btn.setTitle(text, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(btn)
        btn.heightAnchor.constraint(equalToConstant: 39).isActive = true
        btn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        btn.topAnchor.constraint(equalTo: bottom_anchor, constant: 20).isActive = true
        bottom_anchor = btn.bottomAnchor
        elem = btn
        return btn
    }
    
    public func addLastElement(){
        // add bottom anchor to make it scroll on last text element
        elem.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
