import Foundation
import Testing
@testable import Nowly

@Test func favoriteEntityUsesActivityIdentifierAndName() {
    let id = UUID()
    let entity = FavoriteActivityEntity(id: id, name: "Sport")

    #expect(entity.id == id)
    #expect(entity.name == "Sport")
}
