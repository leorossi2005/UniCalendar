//
//  CustomLines.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 31/08/2026.
//  Copyright (C) 2026 Leonardo Rossi
//  SPDX-License-Identifier: GPL-3.0-or-later
//

import SwiftUI

struct HorizontalLine: View {
    var color: Color
    var lineWidth: CGFloat
    var dash: [CGFloat] = []
    
    var body: some View {
        if dash.isEmpty {
            LineShape(lineWidth: lineWidth)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(height: lineWidth)
        } else {
            AdaptiveDashedLineShape(
                lineWidth: lineWidth,
                dashLength: dash[0],
                gapLength: dash.count > 1 ? dash[1] : dash[0],
                isHorizontal: true
            )
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)) // Niente parametro 'dash' qui!
            .frame(height: lineWidth)
        }
    }
    
    private struct LineShape: Shape {
        var lineWidth: CGFloat
        
        nonisolated func path(in rect: CGRect) -> Path {
            var path = Path()
            let inset = lineWidth / 2
            
            path.move(to: CGPoint(x: inset, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width - inset, y: rect.midY))
            return path
        }
    }
}

struct VerticalLine: View {
    var color: Color
    var lineWidth: CGFloat
    var dash: [CGFloat] = []
    
    var body: some View {
        if dash.isEmpty {
            LineShape(lineWidth: lineWidth)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: lineWidth)
        } else {
            AdaptiveDashedLineShape(
                lineWidth: lineWidth,
                dashLength: dash[0],
                gapLength: dash.count > 1 ? dash[1] : dash[0],
                isHorizontal: false
            )
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: lineWidth)
        }
    }
    
    private struct LineShape: Shape {
        var lineWidth: CGFloat
        
        nonisolated func path(in rect: CGRect) -> Path {
            var path = Path()
            let inset = lineWidth / 2
            
            path.move(to: CGPoint(x: rect.midX, y: inset))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.height - inset))
            return path
        }
    }
}

private struct AdaptiveDashedLineShape: Shape {
    var lineWidth: CGFloat
    var dashLength: CGFloat
    var gapLength: CGFloat
    var isHorizontal: Bool
    
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = lineWidth / 2
        
        let start = inset
        let end = isHorizontal ? (rect.width - inset) : (rect.height - inset)
        let totalLength = end - start
        
        guard totalLength > 0 else { return path }
        
        var count = Int(round((totalLength + gapLength) / (dashLength + gapLength)))
        count = max(1, count)
        
        if count == 1 {
            let maxDash = min(dashLength, totalLength)
            if isHorizontal {
                path.move(to: CGPoint(x: start, y: rect.midY))
                path.addLine(to: CGPoint(x: start + maxDash, y: rect.midY))
            } else {
                path.move(to: CGPoint(x: rect.midX, y: start))
                path.addLine(to: CGPoint(x: rect.midX, y: start + maxDash))
            }
            return path
        }
        
        let actualGap = (totalLength - (CGFloat(count) * dashLength)) / CGFloat(count - 1)
        
        for i in 0..<count {
            let offset = start + CGFloat(i) * (dashLength + actualGap)
            if isHorizontal {
                path.move(to: CGPoint(x: offset, y: rect.midY))
                path.addLine(to: CGPoint(x: offset + dashLength, y: rect.midY))
            } else {
                path.move(to: CGPoint(x: rect.midX, y: offset))
                path.addLine(to: CGPoint(x: rect.midX, y: offset + dashLength))
            }
        }
        
        return path
    }
}
