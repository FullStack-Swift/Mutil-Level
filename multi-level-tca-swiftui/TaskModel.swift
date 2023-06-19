//
//  TaskModel.swift
//  TaskApp
//
//  Created by Nguyen Phong on 6/19/23.
//

import Foundation
import ComposableArchitecture

public struct TaskModel: Codable, Identifiable, Equatable {
  public var id: UUID = .init()
  var name: String = ""
  var isCompleted: Bool = false
  var parentID: UUID?
}

extension TaskModel {
  func with(_ block: (inout Self) -> Void) -> Self {
    var clone = self
    block(&clone)
    return clone
  }
}

extension TaskModel {
  func asTreeNode() -> TreeNode<TaskModel> {
    TreeNode<TaskModel>(value: self, id: self.id)
  }
}

extension TaskModel {
  func levelOn(_ array: IdentifiedArrayOf<TaskModel>? = nil) -> Int {
    var level: Int = 0
    if let array = array {
      if let parentID = parentID, let parent = array[id: parentID] {
        level += 1
        return level + parent.levelOn(array)
      }
    }
    return level
  }
}


extension IdentifiedArrayOf where Element == TaskModel {
  func asTreeNode() -> TreeNode<TaskModel> {
    let rootTreeNode: TreeNode<TaskModel> = .init(value: .init())
    for item in self {
      if let parentID = item.parentID {
        if let treeNode = rootTreeNode.search(id: parentID) {
          treeNode.addChild(item.asTreeNode())
        } else {
          rootTreeNode.addChild(buildTreeNode(with: item))
        }
      } else {
        rootTreeNode.addChild(item.asTreeNode())
      }
    }
    return rootTreeNode
  }

  func buildTreeNode(with model: TaskModel) -> TreeNode<TaskModel> {
    if let parentID = model.parentID, let parent = self[id: parentID as! ID] {
      parent.asTreeNode().addChild(model.asTreeNode())
      return buildTreeNode(with: parent)
    } else {
      return model.asTreeNode()
    }
  }
}


extension TreeNode where T == TaskModel {
  func makeChildrenCompleted(isCompleted: Bool) {
    for item in children {
      item.value.isCompleted = isCompleted
      item.makeChildrenCompleted(isCompleted: isCompleted)
    }
  }

  func makeParentCompleted() {
    if let parent = self.parent {
      for item in parent.children {
        if item.value.isCompleted == false {
          parent.value.isCompleted = false
          parent.makeParentCompleted()
          return
        }
        parent.value.isCompleted = true
        parent.makeParentCompleted()
      }
    }
  }

  func makeSelfCompleted() {
    for item in children {
      if item.value.isCompleted == false {
        self.value.isCompleted = false
        return
      }
    }
    self.value.isCompleted = true
  }

  func makeSelfAndParentCompleted() {
    makeSelfCompleted()
    makeParentCompleted()
  }
}
