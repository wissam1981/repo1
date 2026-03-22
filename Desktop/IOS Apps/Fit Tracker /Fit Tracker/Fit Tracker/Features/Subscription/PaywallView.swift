import SwiftUI
import StoreKit

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var products: [Product] = []
    @State private var selectedProduct: Product?
    @State private var isLoading = false
    @State private var appear = false

    // Animation states
    @State private var orb1Rotation: Double = 0
    @State private var orb2Rotation: Double = 0
    @State private var orb3Rotation: Double = 0
    @State private var buttonPulse: CGFloat = 1.0

    private let features: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("brain.head.profile.fill", "AI Coach", "Smart chat with colored insights", .orange),
        ("fork.knife", "Smart Meal Plans", "AI-generated daily meal plans", Color(hex: "#34d399")),
        ("camera.viewfinder", "Meal Scan", "Snap a photo, log your food", .pink),
        ("barcode.viewfinder", "Barcode Scan", "Instant food lookup", .cyan),
        ("bed.double.fill", "Recovery Advisor", "Know when to rest or go hard", Color(hex: "#a78bfa")),
        ("bell.badge.fill", "Smart Nudges", "Proactive meal reminders", Color(hex: "#fb923c")),
        ("chart.bar.xaxis", "Weekly AI Digest", "Personalized weekly reports", .purple),
        ("chart.line.uptrend.xyaxis", "Analytics", "Deep nutrition & workout insights", .blue),
        ("wand.and.stars", "AI Workout Plans", "Auto-generated training programs", ThemeColors.primary),
        ("arrow.triangle.2.circlepath", "Exercise Swaps", "AI-matched alternatives mid-workout", Color(hex: "#f87171")),
        ("flame.fill", "Progressive Overload", "Auto-suggest weight & rep increases", .orange),
        ("target", "Goal Auto-Adjust", "AI tunes your targets to your habits", Color(hex: "#22d3ee")),
        ("clock.badge.checkmark", "Smart Home Screen", "Time-based insights & tips", Color(hex: "#a78bfa"))
    ]

    var body: some View {
        ZStack {
            // MARK: - Animated Background
            ThemeColors.backgroundDark.ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(Color(hex: "#f97316").opacity(0.4))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -200)
                    .rotationEffect(.degrees(orb1Rotation))

                Circle()
                    .fill(Color(hex: "#ef4444").opacity(0.3))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: 150, y: 100)
                    .rotationEffect(.degrees(orb2Rotation))

                Circle()
                    .fill(Color(hex: "#8b5cf6").opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 70)
                    .offset(x: -50, y: 300)
                    .rotationEffect(.degrees(orb3Rotation))
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    Spacer()
                    Text("Restore")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .onTapGesture {
                            Task {
                                isLoading = true
                                await subscriptionManager.restorePurchases()
                                isLoading = false
                                if subscriptionManager.isSubscribed { dismiss() }
                            }
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // MARK: - Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .orange.opacity(0.5), radius: 20, y: 10)

                                Image(systemName: "flame.fill")
                                    .font(.system(size: 38))
                                    .foregroundStyle(.white)
                            }
                            .scaleEffect(appear ? 1 : 0.5)
                            .opacity(appear ? 1 : 0)

                            VStack(spacing: 6) {
                                Text("FuelIQ ")
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                + Text("Elite")
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(hex: "#fba24f")) // lighter orange

                                Text("Unlock all AI-powered tracking, planning, and contextual coaching features.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 24)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                        // MARK: - Features List (Glassmorphism)
                        VStack(spacing: 0) {
                            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(feature.color.opacity(0.15))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: feature.icon)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(feature.color)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(feature.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text(feature.subtitle)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)

                                if index < features.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .background(.ultraThinMaterial)
                        .background(Color.white.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 30)

                        // MARK: - Plans
                        VStack(spacing: 16) {
                            ForEach(products.sorted(by: { $0.id > $1.id })) { product in
                                let isYearly = product.id == SubscriptionManager.yearlyProductID
                                planCard(product: product, isYearly: isYearly)
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 40)

                        Spacer().frame(height: 120) // Give space for bottom button
                    }
                }
            }

            // MARK: - Floating Subscribe Button
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        guard let product = selectedProduct else { return }
                        Task {
                            isLoading = true
                            await subscriptionManager.purchase(productID: product.id)
                            isLoading = false
                            if subscriptionManager.isSubscribed { dismiss() }
                        }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Start Free Trial")
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: selectedProduct != nil
                                    ? [Color(hex: "#f97316"), Color(hex: "#ef4444")]
                                    : [.gray.opacity(0.5), .gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color(hex: "#ef4444").opacity(selectedProduct != nil ? 0.4 : 0), radius: 16, y: 8)
                        .scaleEffect(buttonPulse)
                    }
                    .disabled(selectedProduct == nil || isLoading)

                    Text("Cancel anytime · Auto-renews · No commitments")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 34)
                .background(
                    LinearGradient(
                        colors: [ThemeColors.backgroundDark.opacity(0), ThemeColors.backgroundDark, ThemeColors.backgroundDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .ignoresSafeArea()
        }
        .task {
            await loadProducts()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { appear = true }
            startAnimations()
        }
    }

    // MARK: - Plan Card

    private func planCard(product: Product, isYearly: Bool) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            withAnimation(.spring(response: 0.3)) { selectedProduct = product }
        } label: {
            HStack(spacing: 16) {
                // Custom Checkbox
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "#f97316") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#f97316"))
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Annual Plan" : "Monthly Plan")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)

                        if isYearly {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#ec4899"))
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.displayPrice + (isYearly ? " / year" : " / month"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                if isYearly {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Save 50%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "#34d399")) // Success Green
                        Text("Just $4.16/mo")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .background(isSelected ? Color(hex: "#f97316").opacity(0.1) : Color.white.opacity(0.02))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? Color(hex: "#f97316").opacity(0.6) : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Load Products & Animations

    private func loadProducts() async {
        do {
            products = try await Product.products(for: [
                SubscriptionManager.monthlyProductID,
                SubscriptionManager.yearlyProductID
            ])
            selectedProduct = products.first(where: { $0.id == SubscriptionManager.yearlyProductID }) ?? products.first
        } catch {
            print("[Paywall] Failed to load products: \(error.localizedDescription)")
        }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            orb1Rotation = 360
        }
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            orb2Rotation = -360
        }
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            orb3Rotation = 360
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            buttonPulse = 1.04
        }
    }
}
