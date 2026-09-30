import UIKit

/// Image assets for native GLMapImage drawables. UIKit only rasterizes the artwork;
/// GLMap positions, scales and renders every marker on the terrain.
enum DemoTourArtwork {
    static let accent = UIColor(red: 0.29, green: 0.32, blue: 0.94, alpha: 1)
    static let ink = UIColor(red: 0.13, green: 0.17, blue: 0.24, alpha: 1)
    private static let userBlue = UIColor(red: 0.18, green: 0.47, blue: 0.97, alpha: 1)

    static func pin() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 48, height: 58)).image { _ in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 24, y: 55))
            path.addCurve(to: CGPoint(x: 4, y: 24), controlPoint1: CGPoint(x: 17, y: 44), controlPoint2: CGPoint(x: 4, y: 37))
            path.addArc(withCenter: CGPoint(x: 24, y: 24), radius: 20, startAngle: .pi, endAngle: 0, clockwise: true)
            path.addCurve(to: CGPoint(x: 24, y: 55), controlPoint1: CGPoint(x: 44, y: 37), controlPoint2: CGPoint(x: 31, y: 44))
            path.close()
            accent.setFill()
            path.fill()
            UIColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()
            let symbol = UIImage(systemName: "fork.knife", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))
            symbol?.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: CGRect(x: 14, y: 13, width: 20, height: 23))
        }
    }

    static func startDot() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 18, height: 18)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 18, height: 18)).fill()
            accent.setFill()
            UIBezierPath(ovalIn: CGRect(x: 4, y: 4, width: 10, height: 10)).fill()
        }
    }

    static func finishRing() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 36, height: 36)).image { _ in
            accent.setStroke()
            let ring = UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: 32, height: 32))
            ring.lineWidth = 3
            ring.stroke()
        }
    }

    static func userDot() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 60, height: 60)).image { context in
            userBlue.withAlphaComponent(0.15).setFill()
            UIBezierPath(ovalIn: CGRect(x: 6, y: 6, width: 48, height: 48)).fill()
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: ink.withAlphaComponent(0.25).cgColor)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 18, y: 18, width: 24, height: 24)).fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            userBlue.setFill()
            UIBezierPath(ovalIn: CGRect(x: 21, y: 21, width: 18, height: 18)).fill()
        }
    }

    static func userArrow() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 60, height: 60)).image { _ in
            let triangle = UIBezierPath()
            triangle.move(to: CGPoint(x: 30, y: 1))
            triangle.addLine(to: CGPoint(x: 23, y: 14))
            triangle.addQuadCurve(to: CGPoint(x: 37, y: 14), controlPoint: CGPoint(x: 30, y: 11))
            triangle.close()
            userBlue.setFill()
            triangle.fill()
            UIColor.white.setStroke()
            triangle.lineWidth = 2
            triangle.lineJoinStyle = .round
            triangle.stroke()
        }
    }
}
