//
//  StoryCell.swift
//  Hacker News
//
//  Created by Trevor Behlman on 4/20/19.
//  Copyright © 2019 Trevor Behlman. All rights reserved.
//

import UIKit
import FlexLayout

class StoryCell: UITableViewCell {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    func configure(_ story: Story?) {
        if let story = story {
            titleLabel.text = story.title
            detailLabel.text = "\(story.descendants) comment\(story.descendants == 1 ? "" : "s")  \(story.domain)"
        } else {
            titleLabel.text = " "
            detailLabel.text = " "
        }
        titleLabel.flex.markDirty()
        detailLabel.flex.markDirty()
    }
    
    func setupViews() {
        contentView.flex.define { flex in
            flex.paddingVertical(10)
            flex.paddingHorizontal(14)
            flex.alignItems(.stretch)
            flex.addItem(titleLabel).grow(1)
            flex.addItem(detailLabel).marginTop(6)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    fileprivate func layout() {
        contentView.flex.layout(mode: .adjustHeight)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // 1) Set the contentView's width to the specified size parameter
        contentView.flex.width(size.width)
        
        // 2) Layout contentView flex container
        layout()
        
        // Return the flex container new size
        return contentView.frame.size
    }
}
