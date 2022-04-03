//
//  LiveDocument.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/3/22.
//

import Foundation

import UIKit
struct TempRectChar {
    private static let font: UIFont = UIFont.systemFont(ofSize: 20.0)
    
    public let char: Character
    public let height: CGFloat = Self.font.lineHeight
    public var width: CGFloat {
        NSAttributedString(string: String(char), attributes: [.font: Self.font]).size().width
    }
}

struct LiveLine {
    public typealias Element = TempRectChar
    public typealias Index = Int
    var startIndex: Index { chars.startIndex }
    var endIndex: Index { chars.endIndex }
    func index(_ original: Index, offsetBy offset: Index) -> Index {
        return chars.index(original, offsetBy: offset)
    }
    subscript(_ index: Index) -> Element {
        return chars[index]
    }
    subscript(_ range: Range<Index>) -> ArraySlice<Element> {
        return chars[range]
    }
    
    let chars: [Element]
    
    let origin: CGPoint
    
    init(chars: [Element], origin: CGPoint) {
        self.chars = chars
        self.origin = origin
        self.width = chars.map(\.width).reduce(0, +)
    }
    
    let height = CustomTextLabel.font.lineHeight
    let width: CGFloat
}

extension Collection where Element == LiveLine {
    func closest(to point: CGPoint) -> Element? {
        guard var candidate: Element = first else { return nil }
        var minDistance: CGFloat = .infinity
        for element in self {
            let corners: [CGPoint] = [
                element.origin,
                .init(x: element.origin.x, y: element.origin.y + element.height),
                .init(x: element.origin.x + element.width, y: element.origin.y),
                .init(x: element.origin.x + element.width, y: element.origin.y + element.height)
            ]

            for corner in corners {
                let distance = corner.distance(to: point)
                if distance < minDistance {
                    minDistance = distance
                    candidate = element
                }
            }
        }

        return candidate
    }
}

struct LiveDocument {
    
    public let lines: [LiveLine]
    
    init(_ string: String) {
        var result: [LiveLine] = []
        for (idx, substr) in string.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let chars = substr.map { LiveLine.Element(char: $0) }
            let tempOrigin = CGPoint(x: CGFloat(idx) * 100, y: CGFloat(idx) * 100)
            result.append(LiveLine(chars: chars, origin: tempOrigin))
        }
        
        self.lines = result
    }
    
    var text: String {
        lines
            .map { (line: LiveLine) in String(line.chars.map(\.char)) }
            .joined(separator: "\n")
    }
    
    subscript(_ range: Range<LiveDocument.Index>) -> String {
        guard range.isEmpty == false else { return "" }
        
        guard range.lowerBound != .invalid, range.upperBound != .invalid else {
            assert(false, "Invalid range")
            return ""
        }
        
        if range.lowerBound.row == range.upperBound.row {
            let line = lines[range.lowerBound.row]
            let substring = line[range.lowerBound.column..<range.upperBound.column]
            return String(substring.map(\.char))
        } else {
            let startLine = lines[range.lowerBound.row]
            let endLine = lines[range.upperBound.row]
            let middleLines = lines[(range.lowerBound.row + 1)..<range.upperBound.row]
            
            let start = startLine[range.lowerBound.column..<startLine.endIndex]
            let middle = middleLines
                .map { (line: LiveLine) in String(line.chars.map(\.char)) }
                .joined(separator: "\n")
            let end = endLine[endLine.startIndex..<range.upperBound.column]
            
            if middle.isEmpty {
                return start.map(\.char) + "\n" + end.map(\.char)
            } else {
                return start.map(\.char) + "\n" + middle + "\n" + end.map(\.char)
            }
        }
    }
    
    var startIndex: LiveDocument.Index {
        guard let first = lines.first else {
            return .invalid
        }
        
        return .init(row: 0, column: first.startIndex)
    }
    
    var endIndex: LiveDocument.Index {
        guard let last = lines.last else {
            return .invalid
        }
        
        return .init(row: lines.count - 1, column: last.endIndex)
    }
    
    func index(_ original: LiveDocument.Index, offsetBy offset: Int) -> LiveDocument.Index {
        if offset == 0 {
            return original
        } else if offset > 0 {
            var offset = offset
            var row = original.row
            var column = original.column
            while true {
                guard row < lines.count else {
                    return .invalid
                }

                /// Check if offset exceeds line length.
                let line = lines[row]
                column = line.startIndex
                let remaining = line.chars.distance(from: column, to: line.endIndex)
                
                if remaining < offset {
                    /// If so, move to next line and repeat.
                    offset -= remaining
                    row += 1
                } else {
                    let newColumn = line.index(column, offsetBy: offset)
                    return .init(row: row, column: newColumn)
                }
            }
        } else {
            /// Make offset positive.
            var offset = -offset
            var row = original.row
            var column = original.column
            while true {
                guard row >= 0 else {
                    return .invalid
                }

                /// Check if offset exceeds line length.
                let line = lines[row]
                column = line.endIndex
                let remaining = line.chars.distance(from: line.startIndex, to: column)
                
                if remaining < offset {
                    /// If so, move to previous line and repeat.
                    offset -= remaining
                    row -= 1
                } else {
                    let newColumn = line.index(column, offsetBy: -offset)
                    return .init(row: row, column: newColumn)
                }
            }
        }
    }
    
    var isEmpty: Bool {
        lines.isEmpty
    }
}
