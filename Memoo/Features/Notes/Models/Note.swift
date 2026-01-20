import SwiftData
import Foundation

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String = "Untitled",
        content: String = "",
        order: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
