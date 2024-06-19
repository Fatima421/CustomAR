//
//  NSAttributedString.swift
//  
//
//  Created by Fatima Syed on 19/6/24.
//

import UIKit

extension NSAttributedString {
    static func makeWith(text: String?, font: UIFont?, color: UIColor? = nil, lineHeight: CGFloat? = nil, letterSpacing: CGFloat? = nil, alignment: NSTextAlignment? = nil, truncateTail: Bool = false) -> NSAttributedString? {
        guard let text = text,
              let font = font else {
            return nil
        }

        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = font

        if let color = color {
            attributes[.foregroundColor] = color
        }

        if let letterSpacing = letterSpacing {
            attributes[.kern] = letterSpacing
        }

        if lineHeight != nil || alignment != nil {
            let paragraph = NSMutableParagraphStyle()
            if let lineHeight = lineHeight {
                paragraph.minimumLineHeight = lineHeight
            }
            if let align = alignment {
                paragraph.alignment = align
            }

            if truncateTail {
                paragraph.lineBreakMode = .byTruncatingTail
            }

            attributes[.paragraphStyle] = paragraph
        }

        return NSAttributedString(string: text, attributes: attributes)
    }
}
