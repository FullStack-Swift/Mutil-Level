//
//  TaskApp.swift
//  TaskApp
//
//  Created by Nguyen Phong on 6/19/23.
//

import SwiftUI

@main
struct TaskApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}

extension Int {
  func toDouble() -> Double {
    Double(self)
  }

  func toString() -> String {
    String(self)
  }
}

public extension MutableCollection {
  subscript(safe index: Index) -> Element? {
    get {
      indices.contains(index) ? self[index] : nil
    }
    mutating set {
      if indices.contains(index), let value = newValue {
        self[index] = value
      }
    }
  }
}
