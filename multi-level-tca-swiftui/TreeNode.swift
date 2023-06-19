//
//  TreeNode.swift
//  TaskApp
//
//  Created by Nguyen Phong on 6/19/23.
//

import Foundation

public final class TreeNode<T>: Identifiable {
  public var value: T
  public var id: UUID
  public var isHiddenChildren: Bool
  public weak var parent: TreeNode<T>?
  public var children: [TreeNode<T>]

  public init(
    value: T,
    id: UUID = UUID(),
    isHiddenChildren: Bool = false,
    parent: TreeNode? = nil,
    children: [TreeNode<T>] = []
  ) {
    self.value = value
    self.id = id
    self.isHiddenChildren = isHiddenChildren
    self.children = children
  }
}
// MARK: Equatable
extension TreeNode: Equatable where T: Equatable {
  public static func == (lhs: TreeNode<T>, rhs: TreeNode<T>) -> Bool {
    return lhs.value == rhs.value
    && lhs.id == rhs.id
    && lhs.isHiddenChildren == rhs.isHiddenChildren
    && lhs.parent == rhs.parent
    && lhs.children == rhs.children
  }
}
// MARK: Change
extension TreeNode {
  @discardableResult
  public func with(_ block: (TreeNode) throws -> Void) rethrows -> TreeNode {
    try block(self)
    return self
  }
}
// MARK: add Child and Children
public extension TreeNode {
  func addChild(_ node: TreeNode<T>) {
    children.append(node)
    node.parent = self
  }

  func addChildren(_ children: [TreeNode<T>]) {
    for child in children {
      addChild(child)
    }
  }
}
// MARK: Move Children
public extension TreeNode {
  func moveChildren(fromOffsets: IndexSet, toOffset: Int) {
    children.move(fromOffsets: fromOffsets, toOffset: toOffset)
  }
}
// MARK: remove Child and Children
public extension TreeNode {
  func removeChild(_ node: TreeNode<T>) {
    removeChildWithID(node.id)
  }

  func removeChildren(_ children: [TreeNode<T>]) {
    removeChildrenWithIDs(children.map{$0.id})
  }

  @discardableResult
  func removeChildWithID(_ id: UUID) -> TreeNode<T>? {
    if let item = search(id: id) {
      item.parent?.children.removeAll(where: {$0.id == item.id})
      item.parent = nil
      return item
    }
    return nil
  }

  @discardableResult
  func removeChildrenWithIDs(_ ids: [UUID]) -> [TreeNode<T>?] {
    var items: [TreeNode<T>?] = []
    for id in ids {
      let item = removeChildWithID(id)
      items.append(item)
    }
    return items
  }
}
//MARK: Remove with Value
public extension TreeNode where T: Equatable {
  func remove(value: T) {
    if let id = search(value: value)?.id {
      removeChildWithID(id)
    }
    if self.value == value {
      parent?.children.removeAll(where: {$0.value == value})
    }
    for child in children {
      child.remove(value: value)
    }
  }
}
//MARK: Move with FromID ToID
public extension TreeNode {
  func move(fromID: UUID, toID: UUID) where T: Equatable {
    if let fromTreeNode = search(id: fromID), let toTreeNode = search(id: toID) {
      if fromTreeNode.parent?.id == toTreeNode.parent?.id {
        let parent = toTreeNode.parent
        if let fromTreeNodeIndex = parent?.children.firstIndex(where: {$0.id == fromTreeNode.id}),
           let toTreeNodeIndex = parent?.children.firstIndex(where: {$0.id == toTreeNode.id}) {
          parent?.moveChildren(fromOffsets: IndexSet(integer: fromTreeNodeIndex), toOffset: toTreeNodeIndex)
        }
      } else {
        fromTreeNode.parent?.children.removeAll(where: {$0.id == fromID})
        fromTreeNode.parent = nil
        toTreeNode.parent?.addChild(fromTreeNode)
        let parent = toTreeNode.parent
        if let fromTreeNodeIndex = parent?.children.firstIndex(where: {$0.id == fromTreeNode.id}),
           let toTreeNodeIndex = parent?.children.firstIndex(where: {$0.id == toTreeNode.id}) {
          parent?.moveChildren(fromOffsets: IndexSet(integer: fromTreeNodeIndex), toOffset: toTreeNodeIndex)
        }
      }
    }
  }
}
// MARK: Extension Get
public extension TreeNode {
  /// Get array TreeNode
  /// - Returns: Convert a TreeNode to an array TreeNode with children
  func arrayTreeNode() -> [TreeNode<T>] {
    var arrayTreeNode = [TreeNode<T>]()
    arrayTreeNode.append(self)
    for child in children {
      arrayTreeNode.append(contentsOf: child.arrayTreeNode())
    }
    return arrayTreeNode
  }
  /// Get array TreeNode
  /// - Returns: Convert a TreeNode to an array TreeNode without rootTreeNode
  func arrayTreeNodeWithoutRootTreeNode() -> [TreeNode<T>] {
    var array = arrayTreeNode()
    array.removeFirst()
    return array
  }
  /// Get array TreeNode
  /// - Returns: Convert a TreeNode to an array TreeNode  without TreeNode hiddenChildren
  func arrayTreeNodeWithoutHiddenChildren() -> [TreeNode<T>] {
    var allTreeNode = [TreeNode<T>]()
    allTreeNode.append(self)
    if !isHiddenChildren {
      for child in children {
        allTreeNode.append(contentsOf: child.arrayTreeNodeWithoutHiddenChildren())
      }
    }
    return allTreeNode
  }
  /// Get array TreeNode
  /// - Returns: Convert a TreeNode to an array TreeNode without rootTreeNode and hiddenChildren
  func arrayTreeNodeWithoutHiddenChildrenandRoot() -> [TreeNode<T>] {
    var array = arrayTreeNodeWithoutHiddenChildren()
    array.removeFirst()
    return array
  }
  /// Get level of TreeNode
  var level: Int {
    var index: Int = 0
    if let parent = parent {
      index += 1
      return index + parent.level
    } else {
      return index
    }
  }
  /// Get all TreeNode in one Level
  /// - Parameter level: level
  /// - Returns: return an array TreeNode without children
  func allchildrenInLevel(_ level: Int) -> [TreeNode<T>] {
    arrayTreeNode().filter{$0.level == level}
  }
}
//MARK: Search
public extension TreeNode where T: Equatable {
  func search(value: T) -> TreeNode? {
    if value == self.value {
      return self
    }
    for child in children {
      if let found = child.search(value: value) {
        return found
      }
    }
    return nil
  }
}
//MARK: Search
public extension TreeNode {
  func search(id: UUID) -> TreeNode? {
    if self.id == id {
      return self
    }
    for child in children {
      if let found = child.search(id: id) {
        return found
      }
    }
    return nil
  }
}
//MARK: description
extension TreeNode: CustomStringConvertible {
  public var description: String {
    var s = "\(value)"
    if !children.isEmpty {
      s += " {" + children.map { $0.description }.joined(separator: ", ") + "}"
    }
    return s
  }
}
