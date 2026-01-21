import Foundation

extension Notification.Name {
    static let createNewTab = Notification.Name("createNewTab")
    static let closeCurrentTab = Notification.Name("closeCurrentTab")
    static let selectNextTab = Notification.Name("selectNextTab")
    static let selectPreviousTab = Notification.Name("selectPreviousTab")
    static let selectTabAtIndex = Notification.Name("selectTabAtIndex")
}
