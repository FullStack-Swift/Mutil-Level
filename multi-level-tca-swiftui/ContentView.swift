//
//  ContentView.swift
//  TaskApp
//
//  Created by Nguyen Phong on 6/19/23.
//

import SwiftUI
import ComposableArchitecture

struct ContentReducer: ReducerProtocol {

  struct State: Equatable {
    fileprivate var taskModels: IdentifiedArrayOf<TaskModel> = []
    var rootTreeNode: TreeNode<TaskModel> = .init(value: .init())
    var flag: Bool = false // flag is a suject for update UI
    var treeNodes: IdentifiedArrayOf<TreeNode<TaskModel>> {
      var array = rootTreeNode
        .arrayTreeNodeWithoutHiddenChildren()
      array.removeFirst()
      return IdentifiedArray(uniqueElements: array)
    }
  }

  enum Action {
    case removeAll
    case toggleExpandingTask(TreeNode<TaskModel>)
    case toggleTask(TreeNode<TaskModel>)
    case createTask(parentID: UUID?)
    case deleteTask(withID: UUID)
    case delete(IndexSet)
    case move(IndexSet, Int)
  }

  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
        case .removeAll:
          state = .init()
        case .toggleExpandingTask(let value):
          // MARK: Using TreeNode
          let treeUpdating = state.rootTreeNode.search(id: value.id)
          treeUpdating?.isHiddenChildren.toggle()
        case .toggleTask(let value):
          guard let treeNode = state.rootTreeNode.search(id: value.id) else {
            return .none
          }
          treeNode.value.isCompleted.toggle()
          let isCompleted = treeNode.value.isCompleted
          treeNode.makeChildrenCompleted(isCompleted: isCompleted)
          treeNode.makeParentCompleted()
        case .createTask(let id):
          var name: String = ""
          if let id = id, let treeNode = state.rootTreeNode.search(id: id) {
            name = "Level " + (treeNode.level + 1).toString() + " with " + treeNode.children.count.toString()
          } else {
            name = "Level 1 with " + state.rootTreeNode.children.count.toString()
          }
          let newTreeNode = TaskModel()
            .with {
              $0.name = name
              $0.parentID = id
            }
            .asTreeNode()
          if let id = id, let treeNode = state.rootTreeNode.search(id: id) {
            treeNode.addChild(newTreeNode)
          } else {
            state.rootTreeNode.addChild(newTreeNode)
          }
          newTreeNode.makeParentCompleted()
        case .deleteTask(let id):
          // MARK: Using TreeNode
          if let treeNode = state.rootTreeNode.removeChildWithID(id) {
            treeNode.makeParentCompleted()
          }
        case .delete(let index):
          // MARK: Using TreeNode
          index.forEach {
            var array = state.rootTreeNode.arrayTreeNodeWithoutHiddenChildren()
            array.removeFirst()
            let id = array[$0].id
            if let treeNode = state.rootTreeNode.removeChildWithID(id) {
              treeNode.makeParentCompleted()
            }
          }
        case .move(let from, let to):
          // MARK: Using TreeNode
          from.forEach { from in
            var array = state.rootTreeNode.arrayTreeNodeWithoutHiddenChildren()
            array.removeFirst()
            guard let fromID = array[safe: from]?.id,
                  let toID = array[safe: to]?.id,
                  fromID != toID
            else {
              return
            }
            let rootTreeNode = state.rootTreeNode
            if let fromTreeNode = rootTreeNode.search(id: fromID),
               let toTreeNode = rootTreeNode.search(id: toID) {
              let parentFromTreeNode = fromTreeNode.parent
              state.rootTreeNode.move(fromID: fromID, toID: toID)
              parentFromTreeNode?.makeSelfAndParentCompleted()
              fromTreeNode.parent?.makeSelfAndParentCompleted()
              toTreeNode.parent?.makeSelfAndParentCompleted()
            }
          }
      }
      state.taskModels = IdentifiedArray(uniqueElements: state.rootTreeNode.arrayTreeNode().compactMap({$0.value}))
      state.flag.toggle()
      return .none
    }
  }
}

struct ContentView: View {

  private let store: StoreOf<ContentReducer>

  @StateObject
  private var viewStore: ViewStoreOf<ContentReducer>

  init(store: StoreOf<ContentReducer>? = nil) {
    let unwrapStore = store ?? Store(
      initialState: ContentReducer.State(),
      reducer: ContentReducer()
    )
    self.store = unwrapStore
    self._viewStore = StateObject(wrappedValue: ViewStore(unwrapStore))
  }

  var body: some View {
    ZStack {
      List {
        ForEach(viewStore.treeNodes) { item in
          HStack {
            Spacer()
              .frame(width: 25*max((item.level - 1), 0).toDouble())
            Image(systemName: item.value.isCompleted ? "checkmark.circle.fill" : "circle")
              .resizable()
              .frame(width: 25, height: 25, alignment: .center)
              .onTapGesture {
                viewStore.send(.toggleTask(item))
              }
            Text(item.value.name)
              .lineLimit(1)
            Spacer()
            Image(systemName: "minus")
              .frame(width: 25, height: 25, alignment: .center)
              .contentShape(Rectangle())
              .onTapGesture {
                viewStore.send(.deleteTask(withID: item.value.id))
              }
            Image(systemName: "plus")
              .frame(width: 25, height: 25, alignment: .center)
              .contentShape(Rectangle())
              .onTapGesture {
                viewStore.send(.createTask(parentID: item.value.id))
              }
            if !item.children.isEmpty {
              Image(systemName: "chevron.right.circle")
                .rotationEffect(item.isHiddenChildren ? .degrees(90) : .degrees(0))
                .onTapGesture {
                  viewStore.send(.toggleExpandingTask(item))
                }
            }
          }
        }
        .onDelete(perform: { index in
          viewStore.send(.delete(index))
        })
        .onMove { from, to in
          viewStore.send(.move(from, to))
        }
      }
      .navigationTitle(Text("Task"))
      #if os(iOS)
      .navigationBarItems(leading: leading,trailing: trailing)
      #else
      .toolbar {
        ToolbarItemGroup(placement: .status) {
          Spacer()
          Button("reset") {
            viewStore.send(.removeAll)
          }
          Button("+") {
            viewStore.send(.createTask(parentID: nil))
          }
        }
      }
      #endif
    }
  }

  private var trailing: some View {
    Image(systemName: "plus")
      .onTapGesture {
        viewStore.send(.createTask(parentID: nil))
      }
  }

  private var leading: some View {
    Button("Reset", action: {
      viewStore.send(.removeAll)
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
