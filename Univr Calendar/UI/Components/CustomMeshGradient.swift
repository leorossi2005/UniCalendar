//
//  CustomMeshGradient.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 19/09/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct BaseGradient {
    public static let width: Int = 5
    public static let height: Int = 5
    public static let points: [SIMD2<Float>] =
        [
            SIMD2<Float>(0.0, 0.0),
            SIMD2<Float>(0.18819128, 0.0),
            SIMD2<Float>(0.3893873, 0.0),
            SIMD2<Float>(0.76682913, 0.0),
            SIMD2<Float>(1.0, 0.0),
            SIMD2<Float>(0.0, 0.22116813),
            SIMD2<Float>(0.13762467, 0.16805434),
            SIMD2<Float>(0.5509583, 0.16978663),
            SIMD2<Float>(0.81326586, 0.2985797),
            SIMD2<Float>(1.0, 0.24256144),
            SIMD2<Float>(0.0, 0.40769333),
            SIMD2<Float>(0.23394462, 0.4718591),
            SIMD2<Float>(0.59443676, 0.50261664),
            SIMD2<Float>(0.8532514, 0.51758164),
            SIMD2<Float>(1.0, 0.57693017),
            SIMD2<Float>(0.0, 0.66781336),
            SIMD2<Float>(0.32146293, 0.7300398),
            SIMD2<Float>(0.5224712, 0.7017422),
            SIMD2<Float>(0.833605, 0.8007174),
            SIMD2<Float>(1.0, 0.5517226),
            SIMD2<Float>(0.0, 1.0),
            SIMD2<Float>(0.29515874, 1.0),
            SIMD2<Float>(0.61154246, 1.0),
            SIMD2<Float>(0.8822501, 1.0),
            SIMD2<Float>(1.0, 1.0)
        ]
    public static let colors: [Color] =
        [
            Color(red: 1, green: 0.222, blue: 0.235),
            Color(red: 0, green: 0.534, blue: 1),
            Color(red: 0.381, green: 0.331, blue: 0.960),
            Color(red: -0.002, green: 0.784, blue: 0.701),
            Color(red: 0.998, green: 0.174, blue: 0.335),
            Color(red: 0.674, green: 0.499, blue: 0.369),
            Color(red: 0, green: 0.569, blue: 1),
            Color(red: 1, green: 0.222, blue: 0.235),
            Color(red: 0, green: 0.534, blue: 1),
            Color(red: 0.381, green: 0.331, blue: 0.960),
            Color(red: -0.002, green: 0.784, blue: 0.701),
            Color(red: 0.998, green: 0.174, blue: 0.335),
            Color(red: 0.674, green: 0.499, blue: 0.369),
            Color(red: 0, green: 0.569, blue: 1),
            Color(red: 1, green: 0.222, blue: 0.235),
            Color(red: 0, green: 0.534, blue: 1),
            Color(red: 0.381, green: 0.331, blue: 0.960),
            Color(red: -0.002, green: 0.784, blue: 0.701),
            Color(red: 0.998, green: 0.174, blue: 0.335),
            Color(red: 0.674, green: 0.499, blue: 0.369),
            Color(red: 0, green: 0.569, blue: 1),
            Color(red: 1, green: 0.222, blue: 0.235),
            Color(red: 0, green: 0.534, blue: 1),
            Color(red: 0.381, green: 0.331, blue: 0.960),
            Color(red: -0.002, green: 0.784, blue: 0.701)
        ]
    public static let background: Color = Color(red: 1, green: 1, blue: 1)
    public static let smoothsColors: Bool = true
}

struct CustomMeshGradient: View {
    let width: Int
    let height: Int
    let points: [SIMD2<Float>]
    let colors: [Color]
    let background: Color
    let smoothsColors: Bool

    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: width, height: height,
                points: points, colors: colors,
                background: background,
                smoothsColors: smoothsColors,
                colorSpace: .device
            )
        } else {
            MeshGradientFallbackView(
                width: width, height: height,
                points: points, colors: colors,
                background: background
            )
        }
    }
}

struct MeshGradientFallbackView: View {
    let width: Int
    let height: Int
    let points: [SIMD2<Float>]
    let colors: [Color]
    let background: Color
    let subdivisions: Int = 20

    @State private var image: UIImage?
    @State private var lastSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                } else {
                    background
                }
            }
            .onAppear { render(size: geo.size) }
            .onChange(of: geo.size) { _, newSize in
                render(size: newSize)
            }
        }
    }

    private func render(size: CGSize) {
        guard size != .zero, size != lastSize else { return }
        lastSize = size
        let renderSize = CGSize(width: min(size.width, 300), height: min(size.height, 300))

        let w = width, h = height, pts = points, cols = colors, bg = background, subs = subdivisions

        Task.detached(priority: .userInitiated) {
            let img = Self.rasterize(width: w, height: h, points: pts, colors: cols,
                                      background: bg, canvasSize: renderSize, subdivisions: subs)
            await MainActor.run {
                self.image = img
            }
        }
    }

    nonisolated static func rasterize(width: Int, height: Int, points: [SIMD2<Float>], colors: [Color],
                                       background: Color, canvasSize: CGSize, subdivisions: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return renderer.image { ctx in
            let cg = ctx.cgContext
            UIColor(background).setFill()
            cg.fill(CGRect(origin: .zero, size: canvasSize))

            func point(_ gx: Int, _ gy: Int) -> SIMD2<Float> { points[gy * width + gx] }

            func srgbToLinear(_ c: CGFloat) -> CGFloat {
                c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            func linearToSrgb(_ c: CGFloat) -> CGFloat {
                c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1/2.4) - 0.055
            }

            func rgbaLinear(_ gx: Int, _ gy: Int) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                UIColor(colors[gy * width + gx]).getRed(&r, green: &g, blue: &b, alpha: &a)
                return (srgbToLinear(r), srgbToLinear(g), srgbToLinear(b), a)
            }
            func lerp4(_ a: (CGFloat,CGFloat,CGFloat,CGFloat), _ b: (CGFloat,CGFloat,CGFloat,CGFloat), _ t: CGFloat)
                -> (CGFloat,CGFloat,CGFloat,CGFloat) {
                (a.0+(b.0-a.0)*t, a.1+(b.1-a.1)*t, a.2+(b.2-a.2)*t, a.3+(b.3-a.3)*t)
            }

            for gy in 0..<(height - 1) {
                for gx in 0..<(width - 1) {
                    let p00 = point(gx, gy), p10 = point(gx+1, gy)
                    let p01 = point(gx, gy+1), p11 = point(gx+1, gy+1)
                    let c00 = rgbaLinear(gx, gy), c10 = rgbaLinear(gx+1, gy)
                    let c01 = rgbaLinear(gx, gy+1), c11 = rgbaLinear(gx+1, gy+1)

                    for sy in 0..<subdivisions {
                        for sx in 0..<subdivisions {
                            let u0 = Float(sx) / Float(subdivisions), u1 = Float(sx+1) / Float(subdivisions)
                            let v0 = Float(sy) / Float(subdivisions), v1 = Float(sy+1) / Float(subdivisions)

                            func bPos(_ u: Float, _ v: Float) -> CGPoint {
                                let top = p00 + (p10 - p00) * u
                                let bot = p01 + (p11 - p01) * u
                                let pt = top + (bot - top) * v
                                return CGPoint(x: CGFloat(pt.x) * canvasSize.width,
                                               y: CGFloat(pt.y) * canvasSize.height)
                            }
                            func bColor(_ u: Float, _ v: Float) -> UIColor {
                                let top = lerp4(c00, c10, CGFloat(u))
                                let bot = lerp4(c01, c11, CGFloat(u))
                                let f = lerp4(top, bot, CGFloat(v))
                                return UIColor(red: linearToSrgb(f.0),
                                               green: linearToSrgb(f.1),
                                               blue: linearToSrgb(f.2),
                                               alpha: f.3)
                            }

                            let pA = bPos(u0, v0), pB = bPos(u1, v0)
                            let pC = bPos(u1, v1), pD = bPos(u0, v1)
                            let mid = bColor((u0+u1)/2, (v0+v1)/2)

                            cg.setShouldAntialias(false)
                            cg.beginPath()
                            cg.move(to: pA); cg.addLine(to: pB)
                            cg.addLine(to: pC); cg.addLine(to: pD)
                            cg.closePath()
                            cg.setFillColor(mid.cgColor)
                            cg.fillPath()
                        }
                    }
                }
            }
        }
    }
}
