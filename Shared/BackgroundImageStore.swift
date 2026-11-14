import UIKit

/// The widget's optional background photo, stored as a JPEG in the App Group
/// container so the widget extension can read it.
enum BackgroundImageStore {
    /// Widgets have a tight memory budget, so photos are downscaled to this
    /// many pixels on the longest side before saving.
    private static let maxPixelSize: CGFloat = 1000

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ProfileStore.appGroup)?
            .appendingPathComponent("widget-background.jpg")
    }

    static func load() -> UIImage? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Saves a downscaled copy of `image`, or removes the background when nil.
    static func save(_ image: UIImage?) {
        guard let url = fileURL else { return }
        guard let image else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        try? downscaled(image).jpegData(compressionQuality: 0.85)?.write(to: url, options: .atomic)
    }

    static func downscaled(_ image: UIImage) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        let factor = min(1, maxPixelSize / longest)
        let target = CGSize(width: (size.width * factor).rounded(), height: (size.height * factor).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
