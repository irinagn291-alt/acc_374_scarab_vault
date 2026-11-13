import SwiftUI

enum Palette {
    static let background = Color(hex: 0x071D1A)
    static let panel = Color(hex: 0x113A32)
    static let gold = Color(hex: 0xDDB65E)
    static let glow = Color(hex: 0x46D8C5)
    static let stone = Color(hex: 0x89775A)
    static let ink = Color(hex: 0xF6EBD1)
    static let secondary = Color(hex: 0xADBAA7)
}
extension Color {
    init(hex: UInt) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}
extension View {
    func panel() -> some View {
        self.padding(16).background(Palette.panel.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.gold.opacity(0.24), lineWidth: 1))
    }
    func page() -> some View {
        self.frame(maxWidth: 760).padding(.horizontal, 16).padding(.bottom, 24).frame(maxWidth: .infinity)
    }
}
struct StoneBackground: View {
    var body: some View {
        ZStack {
            Palette.background
            Canvas { context, size in
                for row in 0..<50 {
                    let y = CGFloat(row) * 43
                    var line = Path(); line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: size.width, y: y + 2))
                    context.stroke(line, with: .color(Palette.stone.opacity(0.065)), lineWidth: 1)
                    for col in 0..<12 {
                        let x = CGFloat(col) * 96 + (row % 2 == 0 ? 0 : 48)
                        var seam = Path(); seam.move(to: CGPoint(x: x, y: y)); seam.addLine(to: CGPoint(x: x + 7, y: y + 43))
                        context.stroke(seam, with: .color(Palette.stone.opacity(0.05)), lineWidth: 1)
                    }
                }
            }
            LinearGradient(colors: [.clear, Palette.background.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}
struct GoldButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.vaultFont(17, weight: .semibold, design: .serif)
            .frame(maxWidth: .infinity).frame(minHeight: 52)
            .foregroundStyle(Palette.background)
            .background(LinearGradient(colors: [Color(hex: 0xF1D88B), Palette.gold, Color(hex: 0xAE813C)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xF6E3AA), lineWidth: 1).padding(3))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
struct Eyebrow: View {
    let text: String
    var body: some View { Text(text).vaultFont(12, weight: .semibold).tracking(2).foregroundStyle(Palette.gold) }
}
struct ScarabMark: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Canvas { context, _ in
                for side in [-1.0, 1.0] {
                    for feather in 0..<5 {
                        let y = h * (0.35 + Double(feather) * 0.075)
                        var p = Path(); p.move(to: CGPoint(x: w * 0.5, y: h * 0.55))
                        p.addQuadCurve(to: CGPoint(x: w * (0.5 + side * 0.46), y: y - h * 0.18), control: CGPoint(x: w * (0.5 + side * 0.38), y: y + h * 0.22))
                        p.addLine(to: CGPoint(x: w * (0.5 + side * 0.43), y: y - h * 0.25))
                        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.48), control: CGPoint(x: w * (0.5 + side * 0.25), y: y + h * 0.05))
                        context.fill(p, with: .color(Palette.gold.opacity(0.9 - Double(feather) * 0.1)))
                    }
                }
                let body = CGRect(x: w * 0.4, y: h * 0.33, width: w * 0.2, height: h * 0.45)
                context.fill(Path(ellipseIn: body), with: .linearGradient(Gradient(colors: [Palette.gold, Palette.stone]), startPoint: .zero, endPoint: CGPoint(x: w, y: h)))
                context.fill(Path(ellipseIn: CGRect(x: w * 0.43, y: h * 0.2, width: w * 0.14, height: h * 0.16)), with: .color(Palette.gold))
                context.stroke(Path(ellipseIn: CGRect(x: w * 0.41, y: h * 0.01, width: w * 0.18, height: h * 0.2)), with: .color(Palette.gold), lineWidth: 2)
                var seam = Path(); seam.move(to: CGPoint(x: w * 0.5, y: h * 0.38)); seam.addLine(to: CGPoint(x: w * 0.5, y: h * 0.74))
                context.stroke(seam, with: .color(Palette.background), lineWidth: 2)
            }
        }.accessibilityHidden(true)
    }
}
struct TempleArt: View {
    var opened = false
    var chapter = 0
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                RadialGradient(colors: [Palette.glow.opacity(opened ? 0.25 : 0.08), .clear], center: .center, startRadius: 5, endRadius: w * 0.5)
                Circle().stroke(Palette.gold.opacity(0.22), lineWidth: 1).frame(width: h * 0.8).offset(y: -h * 0.1)
                Circle().stroke(Palette.gold.opacity(0.12), lineWidth: 1).frame(width: h * 0.9).offset(y: -h * 0.1)
                HStack(spacing: opened ? 48 : 3) {
                    ForEach(0..<2) { side in
                        ZStack {
                            UnevenRoundedRectangle(topLeadingRadius: side == 0 ? 36 : 0, topTrailingRadius: side == 1 ? 36 : 0)
                                .fill(LinearGradient(colors: [Palette.stone.opacity(0.65), Palette.panel, Palette.background], startPoint: .topLeading, endPoint: .bottomTrailing))
                            VStack(spacing: 16) {
                                ForEach(0..<3) { n in Image(systemName: Glyph(rawValue: (n + side + chapter) % 6)!.icon).vaultFont(18).foregroundStyle(Palette.gold.opacity(0.5)) }
                            }
                        }.frame(width: min(w * 0.21, 100), height: h * 0.67)
                            .overlay(Rectangle().stroke(Palette.gold.opacity(0.45), lineWidth: 2))
                    }
                }.offset(y: h * 0.1)
                VStack(spacing: 0) {
                    ScarabMark().frame(width: 120, height: 72)
                    Rectangle().fill(LinearGradient(colors: [Palette.stone, Palette.gold.opacity(0.65), Palette.stone], startPoint: .leading, endPoint: .trailing)).frame(width: min(w * 0.72, 330), height: 10)
                    Spacer()
                    ForEach(0..<3) { step in Rectangle().fill(Palette.stone.opacity(0.4 - Double(step) * 0.08)).frame(width: min(w * 0.7 + CGFloat(step * 20), 380), height: 7).padding(.top, 2) }
                }.padding(.top, 8)
            }
        }.frame(height: 240).accessibilityHidden(true)
    }
}

struct VaultFont: ViewModifier {
    @ScaledMetric(relativeTo: .body) var size: CGFloat = 17
    var weight: Font.Weight
    var design: Font.Design
    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body); self.weight = weight; self.design = design
    }
    func body(content: Content) -> some View { content.font(.system(size: size, weight: weight, design: design)) }
}
extension View {
    func vaultFont(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(VaultFont(size: size, weight: weight, design: design))
    }
}
