//
//  LiveString.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/3/22.
//

import Foundation

struct LiveString {
    
    public let lines: [String]
    
    init(_ string: String) {
        self.lines = string
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map({ (substring: Substring) in
                return String(substring)
            })
    }
    
    var text: String {
        lines.joined(separator: "\n")
    }
    
    subscript(_ range: Range<LiveString.Index>) -> String {
        guard range.isEmpty == false else { return "" }
        
        guard range.lowerBound != .invalid, range.upperBound != .invalid else {
            assert(false, "Invalid range")
            return ""
        }
        
        if range.lowerBound.row == range.upperBound.row {
            let line = lines[range.lowerBound.row]
            let substring = line[range.lowerBound.column..<range.upperBound.column]
            return String(substring)
        } else {
            let startLine = lines[range.lowerBound.row]
            let endLine = lines[range.upperBound.row]
            let middleLines = lines[(range.lowerBound.row + 1)..<range.upperBound.row]
            
            let start = startLine[range.lowerBound.column..<startLine.endIndex]
            let middle = middleLines.joined(separator: "\n")
            let end = endLine[endLine.startIndex..<range.upperBound.column]
            
            if middle.isEmpty {
                return start + "\n" + end
            } else {
                return start + "\n" + middle + "\n" + end
            }
        }
    }
    
    var startIndex: LiveString.Index {
        guard let first = lines.first else {
            return .invalid
        }
        
        return .init(row: 0, column: first.startIndex)
    }
    
    var endIndex: LiveString.Index {
        guard let last = lines.last else {
            return .invalid
        }
        
        return .init(row: lines.count - 1, column: last.endIndex)
    }
    
    func index(_ original: LiveString.Index, offsetBy offset: Int) -> LiveString.Index {
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
                let remaining = line.distance(from: column, to: line.endIndex)
                
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
                let remaining = line.distance(from: line.startIndex, to: column)
                
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
