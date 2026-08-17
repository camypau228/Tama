import SwiftUI
import TamaShared

struct SettingsView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    Form {
      Section("Питомец") {
        Toggle("Показывать Sterling", isOn: $model.isPetVisible)
        Toggle("Разрешить движение", isOn: model.movementBinding)

        Picker("Масштаб", selection: $model.scale) {
          ForEach(PetScale.allCases) { scale in
            Text(scale.title).tag(scale)
          }
        }
      }

      Section {
        Text(
          "Sterling только наблюдает за указателем и никогда не перемещает его и не выполняет клики."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 430, height: 250)
  }
}
