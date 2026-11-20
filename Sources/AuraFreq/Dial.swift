import SwiftUI

struct Dial: View {
    let paper: Color
    let hz: Int
    let tune: (Int) -> Void
    private func fraction(_ hz: Int) -> Double { log(Double(hz) / 16) / log(1250) }

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width * 0.94, geo.size.height * 0.69)
            let center = CGPoint(x: geo.size.width * 0.04, y: geo.size.height * 0.60)
            Canvas { ctx, _ in
                func circle(_ r: Double) -> Path {
                    Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: 2*r, height: 2*r))
                }
                func point(_ t: Double, _ r: Double) -> CGPoint {
                    let angle = (-60 + 92 * t) * .pi / 180
                    return CGPoint(x: center.x + r*cos(angle), y: center.y + r*sin(angle))
                }
                ctx.fill(circle(radius), with: .color(.init(white: 0.42)))
                ctx.fill(circle(radius-4), with: .radialGradient(Gradient(colors: [.init(white: 0.20), .init(white: 0.085)]), center: center, startRadius: 0, endRadius: radius))
                for i in 0...120 {
                    let t = Double(i)/120
                    var line = Path()
                    line.move(to: point(t, radius*0.80))
                    line.addLine(to: point(t, radius*(i.isMultiple(of: 10) ? 0.75 : 0.782)))
                    ctx.stroke(line, with: .color(paper.opacity(0.83)), lineWidth: 1)
                }
                for mark in [16, 32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 20000] {
                    let label = mark >= 1000 ? String(mark/1000) + "k" : String(mark)
                    ctx.draw(Text(label).font(.system(size: 13, design: .serif)).foregroundStyle(paper), at: point(fraction(mark), radius*0.89))
                }
                let angle = (-60 + 92*fraction(hz)) * .pi/180
                var needle = Path()
                needle.move(to: CGPoint(x: center.x-4*sin(angle), y: center.y+4*cos(angle)))
                needle.addLine(to: point(fraction(hz), radius*0.82))
                needle.addLine(to: CGPoint(x: center.x+4*sin(angle), y: center.y-4*cos(angle)))
                needle.closeSubpath()
                ctx.fill(needle, with: .color(.red))
                ctx.fill(circle(radius*0.15), with: .conicGradient(Gradient(colors: [.brown,.white,.gray,.brown,.white,.brown]), center: center))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { event in
                let dx = event.location.x-center.x, dy = event.location.y-center.y
                guard dx >= 0, hypot(dx,dy) >= radius*0.15 else { return }
                let t = min(1,max(0,(atan2(dy,dx)*180 / .pi+60)/92))
                tune(Int((16*pow(1250,t)).rounded()))
            })
            .accessibilityElement().accessibilityLabel("Tần số").accessibilityValue("\(hz) Hz")
            .accessibilityAdjustableAction { direction in tune(hz + (direction == .increment ? 1 : -1)) }
        }
    }
}
