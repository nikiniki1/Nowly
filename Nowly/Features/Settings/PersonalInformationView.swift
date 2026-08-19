import SwiftUI

struct PersonalInformationView: View {
    var body: some View {
        ContentUnavailableView(
            "Информация о себе",
            systemImage: "person.crop.circle",
            description: Text("Здесь появятся цели, предпочтения и другие данные для персональных рекомендаций.")
        )
        .navigationTitle("О себе")
    }
}
