import SwiftUI

struct ConfettiView: View {
    let isActive: Bool

    @State private var pieces: [ConfettiPiece] = []
    @State private var startDate: Date? = nil

    private static let palette: [Color] = [
        Color(red: 1.00, green: 0.42, blue: 0.42),
        Color(red: 1.00, green: 0.85, blue: 0.24),
        Color(red: 0.42, green: 0.80, blue: 0.46),
        Color(red: 0.30, green: 0.59, blue: 1.00),
        Color(red: 1.00, green: 0.57, blue: 0.17),
        Color(red: 0.80, green: 0.36, blue: 0.91),
        Color(red: 0.94, green: 0.39, blue: 0.58),
        Color(red: 0.12, green: 0.79, blue: 0.59),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard let start = startDate else { return }
                let t = timeline.date.timeIntervalSince(start)
                for piece in pieces { piece.draw(into: &context, at: t, in: size) }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { fire() }
        }
    }

    private func fire() {
        pieces = (0..<120).map { i in
            ConfettiPiece(
                xFraction:     Double.random(in: 0.05...0.95),
                vx:            Double.random(in: -100...100),
                vy0:           Double.random(in: 480...920),
                rotation0:     Double.random(in: 0 ..< .pi * 2),
                rotationSpeed: Double.random(in: -8...8),
                color:         Self.palette[i % Self.palette.count],
                width:         Double.random(in: 7...14),
                height:        Double.random(in: 5...9),
                delay:         Double.random(in: 0...0.4)
            )
        }
        startDate = Date()
    }
}

private struct ConfettiPiece {
    let xFraction: Double
    let vx: Double
    let vy0: Double
    let rotation0: Double
    let rotationSpeed: Double
    let color: Color
    let width: Double
    let height: Double
    let delay: Double

    private static let gravity = 520.0
    private static let activeDuration = 2.5
    private static let fadeStartFraction = 0.62

    func draw(into context: inout GraphicsContext, at t: Double, in size: CGSize) {
        let dt = t - delay
        guard dt > 0 else { return }
        let alpha = opacity(dt: dt)
        guard alpha > 0 else { return }

        let x = xFraction * size.width + vx * dt
        let y = size.height - (vy0 * dt - 0.5 * Self.gravity * dt * dt)
        let angle = rotation0 + rotationSpeed * dt

        var ctx = context
        ctx.opacity = alpha
        ctx.translateBy(x: x, y: y)
        ctx.rotate(by: Angle(radians: angle))

        let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color))
    }

    private func opacity(dt: Double) -> Double {
        guard dt < Self.activeDuration else { return 0 }
        let fadeBegin = Self.activeDuration * Self.fadeStartFraction
        guard dt > fadeBegin else { return 1 }
        return 1.0 - (dt - fadeBegin) / (Self.activeDuration - fadeBegin)
    }
}
