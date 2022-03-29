//
//  VisionTextResult.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 22/3/22.
//

import UIKit
import Vision

/// Simplified representation of `VNRecognizedText`.
struct VisionTextResult: Sendable {
    let text: String
    let box: Self.Box?
    
    init(_ vn: VNRecognizedText) {
        text = vn.string
        
        let textRange: Range<String.Index> = text.startIndex..<text.endIndex
        if let rect = try? vn.boundingBox(for: textRange) {
            /// The Vision framework has the y axis pointing up, so we need to invert it.
            /// Points are provided in a 1 by 1 box.
            box = Box(
                topLeft: CGPoint(x: rect.topLeft.x, y: 1 - rect.topLeft.y),
                topRight: CGPoint(x: rect.topRight.x, y: 1 - rect.topRight.y),
                bottomLeft: CGPoint(x: rect.bottomLeft.x, y: 1 - rect.bottomLeft.y),
                bottomRight: CGPoint(x: rect.bottomRight.x, y: 1 - rect.bottomRight.y)
            )
        } else {
            box = nil
        }
    }
}

extension VisionTextResult {
    struct Box: Sendable {
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomLeft: CGPoint
        let bottomRight: CGPoint
        
        /// Scale the box from vision's 1x1 bounding box to a `CGPath` in the provided frame.
        public func cgPath(in frame: CGRect) -> CGPath {
            let boxPath = UIBezierPath()
            
            let scaledTopLeft = CGPoint(x: topLeft.x * frame.width + frame.origin.x, y: topLeft.y * frame.height + frame.origin.y)
            boxPath.move(to: scaledTopLeft)
            
            let scaledTopRight = CGPoint(x: topRight.x * frame.width + frame.origin.x, y: topRight.y * frame.height + frame.origin.y)
            boxPath.addLine(to: scaledTopRight)
            
            let scaledBottomRight = CGPoint(x: bottomRight.x * frame.width + frame.origin.x, y: bottomRight.y * frame.height + frame.origin.y)
            boxPath.addLine(to: scaledBottomRight)
            
            let scaledBottomLeft = CGPoint(x: bottomLeft.x * frame.width + frame.origin.x, y: bottomLeft.y * frame.height + frame.origin.y)
            boxPath.addLine(to: scaledBottomLeft)
            
            boxPath.close()

            return boxPath.cgPath
        }
    }
}

struct LiveTextLine: Sendable {

    public let characters: [LiveTextCharacter]
    public let box: BoundingBox

    init?(_ text: VNRecognizedText) {
        let string = text.string
        guard let wholeBox = try? text.boundingBox(for: string.startIndex..<string.endIndex) else {
            assert(false, "Failed to get box for text \(string)")
            return nil
        }
        self.box = BoundingBox(wholeBox)
        
        var chars: [LiveTextCharacter] = []
        var curr = string.startIndex
        while curr < string.endIndex {
            let range = curr..<string.index(after: curr)
            guard let box = try? text.boundingBox(for: range) else {
                assert(false, "Failed to get box for character in text \(string)")
                continue
            }
            chars.append(.init(box: BoundingBox(box), character: string[range]))
            curr = string.index(after: curr)
        }
        
        self.characters = chars
    }
    
    var string: String {
        characters.map(\.character).reduce("", {$0 + $1})
    }
}

struct LiveTextCharacter: Sendable {
    public let box: BoundingBox
    public let character: Substring
}

struct BoundingBox: Sendable {
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomLeft: CGPoint
    public let bottomRight: CGPoint
    
    init(_ observation: VNRectangleObservation) {
        self.topLeft = observation.topLeft
        self.topRight = observation.topRight
        self.bottomLeft = observation.bottomLeft
        self.bottomRight = observation.bottomRight
    }
}
