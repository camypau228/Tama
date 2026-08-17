import PetOverlay
import SwiftUI
import TamaShared

struct MenuBarPopover: View {
  @ObservedObject var model: AppModel

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        SterlingPreview()
          .frame(width: 58, height: 63)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 3) {
          Text("Sterling")
            .font(.headline)
          Text(model.statusText)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      if let startupError = model.startupError {
        Label(startupError, systemImage: "exclamationmark.triangle.fill")
          .font(.caption)
          .foregroundStyle(.red)
          .fixedSize(horizontal: false, vertical: true)
      }

      Divider()

      Toggle("Показывать Sterling", isOn: $model.isPetVisible)
      Toggle("Движение", isOn: model.movementBinding)

      Picker("Масштаб", selection: $model.scale) {
        ForEach(PetScale.allCases) { scale in
          Text(scale.title).tag(scale)
        }
      }
      .pickerStyle(.segmented)

      Divider()

      SettingsLink {
        Label("Настройки…", systemImage: "gear")
      }

      Button {
        model.quit()
      } label: {
        Label("Выйти из Tama", systemImage: "power")
      }
    }
    .padding(16)
    .frame(width: 300)
  }
}

private struct SterlingPreview: NSViewRepresentable {
  func makeNSView(context: Context) -> SterlingPreviewHost {
    SterlingPreviewHost()
  }

  func updateNSView(_ nsView: SterlingPreviewHost, context: Context) {}
}

@MainActor
private final class SterlingPreviewHost: NSView {
  private let content: NSView

  override init(frame frameRect: NSRect) {
    if let atlas = try? SpriteAtlas() {
      let animator = SpriteAnimatorView(atlas: atlas)
      animator.play(.idle)
      content = animator
    } else {
      let imageView = NSImageView()
      imageView.image = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "Sterling")
      imageView.contentTintColor = .secondaryLabelColor
      imageView.imageScaling = .scaleProportionallyUpOrDown
      content = imageView
    }

    super.init(frame: frameRect)
    addSubview(content)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  override func layout() {
    super.layout()
    content.frame = bounds
  }
}
