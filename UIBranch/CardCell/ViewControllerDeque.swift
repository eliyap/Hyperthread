//
//  ViewControllerDeque.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/11/21.
//

import Foundation
import DequeModule

struct ExpandableDeque<Element> {
    private var deque = Deque<Element>()
    
    mutating func prepend(_ element: Element) -> Void {
        deque.prepend(element)
    }
    
    mutating func append(_ element: Element) -> Void {
        deque.append(element)
    }
    
    mutating func popFirst(generator: @escaping () -> Element) -> Element {
        if deque.isEmpty {
            deque.prepend(generator())
        }
        return deque.removeFirst()
    }
    
    mutating func popLast(generator: @escaping () -> Element) -> Element {
        if deque.isEmpty {
            deque.append(generator())
        }
        return deque.removeLast()
    }
}
