//
//  UIScrollView.swift
//  VideoClip
//
//  Created by p-x9 on 2021/04/03.
//  
//

import UIKit

extension UIScrollView {
    var isReachedToBottom: Bool {
        self.contentOffset.y >= (contentSize.height - frame.height)
    }
    var isReachedToTop: Bool {
        self.contentOffset.y <= 0
    }
}
