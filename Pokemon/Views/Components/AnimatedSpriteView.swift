//
//  AnimatedSpriteView.swift
//  Pokemon
//
//  Created by Esther Ramos on 26/09/26.
//

import SwiftUI
import UIKit
import ImageIO

/// The little animated battle sprite, shown inline with no background —
/// it takes up no space until the GIF is ready, then pops in and loops.
struct AnimatedSpriteView: View {
    let pokemonID: Int
    var size: CGFloat = 38

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gif: GIF?

    static func spriteURL(for id: Int) -> URL? {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/\(id).gif")
    }

    var body: some View {
        Group {
            if let gif, !reduceMotion {
                AnimatedImageView(gif: gif)
                    .frame(width: size, height: size)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            } else {
                Color.clear
                    .frame(width: 0, height: 0)
            }
        }
        .task {
            guard !reduceMotion,
                  gif == nil,
                  let url = Self.spriteURL(for: pokemonID),
                  let data = try? await ImageCache.shared.gifData(for: url),
                  let decoded = GIF.decode(data) else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                gif = decoded
            }
        }
    }
}

/// A decoded GIF: its frames plus the total loop duration.
struct GIF {
    let frames: [UIImage]
    let duration: TimeInterval

    static func decode(_ data: Data) -> GIF? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var duration: TimeInterval = 0
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gifProperties = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gifProperties?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                .flatMap { $0 > 0 ? $0 : nil }
                ?? (gifProperties?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? 0.1
            duration += max(delay, 0.02)
            frames.append(UIImage(cgImage: cgImage))
        }
        guard !frames.isEmpty else { return nil }
        return GIF(frames: frames, duration: duration)
    }
}

/// UIImageView does GIF-style frame animation efficiently, so we wrap one.
/// The nearest-neighbor filter keeps the pixel art crisp when scaled up.
private struct AnimatedImageView: UIViewRepresentable {
    let gif: GIF

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.layer.magnificationFilter = .nearest
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.animationImages = gif.frames
        view.animationDuration = gif.duration
        view.startAnimating()
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {}
}
