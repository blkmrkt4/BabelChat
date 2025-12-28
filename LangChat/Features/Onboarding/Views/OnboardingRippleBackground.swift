//
//  OnboardingRippleBackground.swift
//  LangChat
//
//  Animated ripple background for onboarding screens
//  Creates a sophisticated water-drop effect with overlapping circles
//

import SwiftUI

// MARK: - Main Background View

struct OnboardingRippleBackground: View {
    // Customizable parameters
    var backgroundColor: Color = Color(hex: "1a1a1a")
    var rippleColors: [RippleColorScheme] = [
        .gold,
        .lightGold,
        .warmGold
    ]
    var rippleOpacity: Double = 0.20
    var newRippleInterval: ClosedRange<Double> = 2.0...3.5
    var rippleExpansionDuration: Double = 3.0
    var maxConcurrentRipples: Int = 12

    @State private var ripples: [Ripple] = []
    @State private var rippleIdCounter: Int = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                backgroundColor
                    .ignoresSafeArea()

                // Animated ripples
                ForEach(ripples) { ripple in
                    RippleView(
                        ripple: ripple,
                        size: geometry.size,
                        opacity: rippleOpacity,
                        expansionDuration: rippleExpansionDuration
                    )
                }
            }
            .onAppear {
                startRippleGeneration(in: geometry.size)
            }
        }
    }

    // MARK: - Ripple Generation

    private func startRippleGeneration(in size: CGSize) {
        // Don't start if size is invalid
        guard size.width > 0 && size.height > 0 else { return }

        // Create initial ripples
        createRipple(in: size)

        // Schedule continuous ripple creation
        scheduleNextRipple(in: size)
    }

    private func scheduleNextRipple(in size: CGSize) {
        let interval = Double.random(in: newRippleInterval)

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            createRipple(in: size)
            scheduleNextRipple(in: size)
        }
    }

    private func createRipple(in size: CGSize) {
        // Remove old ripples if we have too many
        if ripples.count >= maxConcurrentRipples {
            ripples.removeFirst()
        }

        // Guard against invalid size (can happen during view transitions)
        let margin: CGFloat = 50
        let minWidth = margin * 2 + 10
        let minHeight = margin * 2 + 10

        guard size.width >= minWidth && size.height >= minHeight else {
            // Size too small, skip creating ripple
            return
        }

        // Random position (avoid edges for better visual)
        let x = CGFloat.random(in: margin...(size.width - margin))
        let y = CGFloat.random(in: margin...(size.height - margin))

        // Random color scheme
        let colorScheme = rippleColors.randomElement() ?? .gold

        // Random number of rings (3-4)
        let ringCount = Int.random(in: 3...4)

        let newRipple = Ripple(
            id: rippleIdCounter,
            position: CGPoint(x: x, y: y),
            colorScheme: colorScheme,
            ringCount: ringCount
        )

        rippleIdCounter += 1
        ripples.append(newRipple)

        // Auto-remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleExpansionDuration + 0.5) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }
}

// MARK: - Ripple Data Model

struct Ripple: Identifiable {
    let id: Int
    let position: CGPoint
    let colorScheme: RippleColorScheme
    let ringCount: Int
}

// MARK: - Color Schemes

enum RippleColorScheme {
    case gold
    case lightGold
    case warmGold

    var gradient: Gradient {
        switch self {
        case .gold:
            return Gradient(colors: [
                Color(hex: "D4AF37"),  // Classic gold
                Color(hex: "CD853F")   // Peru/bronze
            ])
        case .lightGold:
            return Gradient(colors: [
                Color(hex: "E6B800"),  // Rich gold
                Color(hex: "B8860B")   // Dark goldenrod
            ])
        case .warmGold:
            return Gradient(colors: [
                Color(hex: "C9A961"),  // Soft gold
                Color(hex: "9B7E46")   // Antique brass
            ])
        }
    }
}

// MARK: - Individual Ripple View

struct RippleView: View {
    let ripple: Ripple
    let size: CGSize
    let opacity: Double
    let expansionDuration: Double

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(0..<ripple.ringCount, id: \.self) { ringIndex in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: ripple.colorScheme.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .opacity(isAnimating ? 0 : opacity)
                    .scaleEffect(isAnimating ? maxScale(for: ringIndex) : 0.1)
                    .position(ripple.position)
                    .animation(
                        .easeInOut(duration: expansionDuration)
                            .delay(Double(ringIndex) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            isAnimating = true
        }
    }

    private func maxScale(for ringIndex: Int) -> CGFloat {
        let baseScale: CGFloat = 3.0
        let increment: CGFloat = 0.5
        return baseScale + (CGFloat(ringIndex) * increment)
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OnboardingRippleBackground()

        // Example onboarding content on top
        VStack(spacing: 40) {
            Spacer()

            Text("Welcome to Fluenca")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Connect with language learners\naround the world")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: {}) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "FFD700"),
                                Color(hex: "FFA500")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
    .ignoresSafeArea()
}
