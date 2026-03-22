import SwiftUI
import PhotosUI

// MARK: - Food Scanner View
// Camera-based food plate scanner powered by GPT-4o-mini vision.
// Free users get 3 scans/day. Premium users get unlimited.

struct FoodScannerView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var selectedImage: UIImage?
    @State private var scannedFoods: [ScannedFoodItem] = []
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var imagePickerItem: PhotosPickerItem?
    @State private var addedItems: Set<String> = []
    @State private var showPaywall = false

    // Animation
    @State private var isPulsing = false
    @State private var rotateRing = false
    @State private var scanLineOffset: CGFloat = -50
    @State private var iconFloat: Bool = false

    // For editing a scanned item
    @State private var itemToEdit: ScannedFoodItem?

    private let scanner = FoodScannerService.shared

    /// Paid subscribers and trial users get unlimited scans.
    private var isPremium: Bool { subscriptionManager.isSubscribed }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                if let img = selectedImage {
                    Color.clear
                        .overlay(
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        )
                        .clipped()
                        .ignoresSafeArea()
                        .blur(radius: isAnalyzing ? 8 : 40)
                        .overlay(Color.black.opacity(isAnalyzing ? 0.6 : 0.85).ignoresSafeArea())
                } else {
                    // Premium Deep Gradient Background
                    LinearGradient(
                        colors: [Color(hex: "#050810"), Color(hex: "#0f172a")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    // Decorative glowing orbs
                    glowingOrb(color: ThemeColors.primary, size: 400, offset: CGSize(width: -150, height: -250), opacity: 0.15)
                    glowingOrb(color: ThemeColors.info, size: 300, offset: CGSize(width: 150, height: 150), opacity: 0.1)
                }

                VStack {
                    if selectedImage == nil {
                        // MARK: Source Selection
                        sourceSelectionView
                    } else if isAnalyzing {
                        // MARK: Analyzing
                        analyzingView
                    } else if !scannedFoods.isEmpty {
                        // MARK: Results
                        resultsView
                    } else if let error = errorMessage {
                        // MARK: Error
                        errorView(error)
                    }
                }
            }
            .navigationTitle("AI Food Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedImage) { _, newImage in
                if newImage != nil {
                    analyzeImage()
                }
            }
            .onChange(of: imagePickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            .sheet(item: $itemToEdit) { scannedFood in
                let foodItem = scannedFood.toFoodItem()
                CustomFoodView(initialFood: foodItem) { editedFood in
                    addedItems.insert(scannedFood.id)
                    Task {
                        await viewModel.addEntry(
                            food: editedFood,
                            quantity: editedFood.servingSizeG,
                            mealType: viewModel.selectedMealType
                        )
                        itemToEdit = nil
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Source Selection

    private var sourceSelectionView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero Icon Section: Animated Scanner
            ZStack {
                // Outer rotating dashed ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [ThemeColors.info.opacity(0.4), .clear, ThemeColors.primary.opacity(0.3), .clear],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .frame(width: 210, height: 210)
                    .rotationEffect(.degrees(rotateRing ? 360 : 0))

                // Middle rotating ring (opposite direction)
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [ThemeColors.primary.opacity(0.3), .clear, ThemeColors.info.opacity(0.2), .clear],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1, dash: [8, 6])
                    )
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(rotateRing ? -360 : 0))

                // Pulsing glow ring 1
                Circle()
                    .fill(ThemeColors.info.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isPulsing ? 1.25 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.6)

                // Pulsing glow ring 2 (delayed)
                Circle()
                    .fill(ThemeColors.primary.opacity(0.06))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.3 : 0.9)
                    .opacity(isPulsing ? 0.0 : 0.5)

                // Inner glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), ThemeColors.info.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: ThemeColors.info.opacity(0.2), radius: 20)

                // Scan line sweeping inside the circle
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [.clear, ThemeColors.info.opacity(0.6), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 90, height: 2)
                    .offset(y: scanLineOffset)

                // Camera icon with float
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.info, ThemeColors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: ThemeColors.info.opacity(0.6), radius: 12)
                    .offset(y: iconFloat ? -4 : 4)

                // Corner brackets
                scannerCorners
            }
            .padding(.bottom, 44)
            .onAppear {
                isPulsing = true
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotateRing = true
                }
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    scanLineOffset = 50
                }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    iconFloat = true
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }

            VStack(spacing: 16) {
                Text("Scan Your Plate")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary)
                    .tracking(-0.5)

                Text("Take a photo of your food and AI will\nprecisely identify items and macros.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                scanLimitBadge
            }

            Spacer()

            // Meal Picker
            VStack(alignment: .leading, spacing: 14) {
                Text("LOGGING FOR")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .tracking(1.2)
                    .padding(.horizontal, 32)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Button {
                                viewModel.selectedMealType = meal
                            } label: {
                                Text(meal.rawValue.capitalized)
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background {
                                        if viewModel.selectedMealType == meal {
                                            Capsule()
                                                .fill(ThemeColors.primary)
                                                .shadow(color: ThemeColors.primary.opacity(0.3), radius: 8, y: 4)
                                        } else {
                                            Capsule()
                                                .fill(ThemeColors.surfaceColor)
                                                .overlay(Capsule().stroke(ThemeColors.surfaceBorder, lineWidth: 1))
                                        }
                                    }
                                    .foregroundStyle(viewModel.selectedMealType == meal ? .white : ThemeColors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 32)

            // Primary Actions
            VStack(spacing: 16) {
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Take Photo")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        LinearGradient(colors: [ThemeColors.primary, ThemeColors.primaryDark],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: ThemeColors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                }

                PhotosPicker(selection: $imagePickerItem, matching: .images) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Choose from Library")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(.ultraThinMaterial)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Analyzing View

    private var analyzingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                if let img = selectedImage {
                    // Pulsing backdrop
                    Circle()
                        .fill(ThemeColors.primary.opacity(0.3))
                        .frame(width: 240, height: 240)
                        .scaleEffect(isPulsing ? 1.4 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)
                    
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .black.opacity(0.6), radius: 25)
                }
                
                // Floating scanning icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    Image(systemName: "viewfinder")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white)
                }
                .offset(y: isPulsing ? -10 : 10)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPulsing)
            }
            .onAppear { isPulsing = true }

            VStack(spacing: 16) {
                Text("Analyzing Plate...")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary)

                VStack(spacing: 8) {
                    Text("Identifying distinct foods and scaling")
                    Text("portion dimensions to calculate macros.")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Header
             HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan Results")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text(String(localized: "\(scannedFoods.count) items identified"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                Spacer()
                
                // Show "Add Selected" instead of "Add All" if we have items
                let selectedCount = addedItems.count
                let totalCount = scannedFoods.count
                let pendingCount = totalCount - selectedCount
                
                if pendingCount > 0 {
                    Button {
                        addAllFoods()
                    } label: {
                        Text(pendingCount == totalCount ? String(localized: "Add All") : String(localized: "Add Remaining"))
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(ThemeColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 8, y: 4)
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ThemeColors.success)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            if !scannedFoods.isEmpty {
                 Text("Tap the + icon to add an item individually, or tap the item to edit its details.")
                     .font(.system(size: 12, weight: .medium))
                     .foregroundStyle(ThemeColors.textSecondary)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .padding(.horizontal, 24)
                     .padding(.bottom, 16)
            }

            // Food list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(scannedFoods) { food in
                        scannedFoodRow(food)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }

            // Bottom Actions
            VStack(spacing: 12) {
                Button {
                    resetScanner()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.viewfinder")
                        Text(addedItems.count == scannedFoods.count ? String(localized: "Scan Another Plate") : String(localized: "Discard & Rescan"))
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(addedItems.count == scannedFoods.count ? ThemeColors.textPrimary : .red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(addedItems.count == scannedFoods.count ? ThemeColors.surfaceBorder : Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Scanned Food Row

    private func scannedFoodRow(_ food: ScannedFoodItem) -> some View {
        let isAdded = addedItems.contains(food.id)

        return HStack(spacing: 16) {
            // Macro circle or placeholder
            ZStack {
                Circle()
                    .fill(isAdded ? ThemeColors.success.opacity(0.15) : ThemeColors.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Text("\(Int(food.calories))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isAdded ? ThemeColors.success : ThemeColors.primary)
                
                Text("kcal")
                    .font(.system(size: 6))
                    .foregroundStyle(isAdded ? ThemeColors.success.opacity(0.7) : ThemeColors.primary.opacity(0.7))
                    .offset(y: 12)
            }

            // Text content container - wrapping it in a Button allows tapping to edit BEFORE adding
            Button {
                if !isAdded {
                    itemToEdit = food
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(food.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isAdded ? ThemeColors.textSecondary : ThemeColors.textPrimary)
                            .lineLimit(1)
                            .strikethrough(isAdded, color: ThemeColors.textSecondary)
                            
                        if !isAdded {
                            Text("EDIT")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(ThemeColors.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().stroke(ThemeColors.surfaceBorder, lineWidth: 1))
                        }
                    }

                    HStack(spacing: 10) {
                        macroLabel(label: "P", value: "\(Int(food.proteinG))g", color: isAdded ? ThemeColors.textSecondary : .orange)
                        macroLabel(label: "C", value: "\(Int(food.carbsG))g", color: isAdded ? ThemeColors.textSecondary : .cyan)
                        macroLabel(label: "F", value: "\(Int(food.fatG))g", color: isAdded ? ThemeColors.textSecondary : .purple)

                        Spacer()

                        Text("\(Int(food.servingSizeG))g")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain) // Prevent row highlighting from affecting layout

            Spacer()

            // Quick act button
            Button {
                if !isAdded {
                    addFood(food)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isAdded ? ThemeColors.success.opacity(0.2) : ThemeColors.surfaceColor)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isAdded ? ThemeColors.success : ThemeColors.primary)
                }
            }
            .disabled(isAdded)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(isAdded ? ThemeColors.success.opacity(0.2) : ThemeColors.surfaceBorder, lineWidth: 1)
                )
        )
    }

    private func macroLabel(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color.opacity(0.8))
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ThemeColors.textSecondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Scan Failed")
                .font(.title3.bold())
                .foregroundStyle(ThemeColors.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                resetScanner()
            } label: {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .frame(width: 180, height: 48)
                    .background(ThemeColors.info)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Actions

    private func analyzeImage() {
        guard let image = selectedImage else { return }

        // Check daily scan limit for free users
        guard ScanUsageTracker.canScan(isPremium: isPremium) else {
            selectedImage = nil
            showPaywall = true
            return
        }

        isAnalyzing = true
        errorMessage = nil
        scannedFoods = []

        Task {
            do {
                let results = try await scanner.analyzePhoto(image)
                ScanUsageTracker.recordScan()
                scannedFoods = results
                isAnalyzing = false
            } catch {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }

    private func addFood(_ food: ScannedFoodItem) {
        let foodItem = food.toFoodItem()
        addedItems.insert(food.id)
        Task {
            await viewModel.addEntry(
                food: foodItem,
                quantity: food.servingSizeG,
                mealType: viewModel.selectedMealType
            )
        }
    }

    /// Adds all scanned foods **sequentially** to avoid race conditions
    /// where concurrent Tasks overwrite each other's todayLog snapshot.
    private func addAllFoods() {
        Task {
            for food in scannedFoods where !addedItems.contains(food.id) {
                let foodItem = food.toFoodItem()
                addedItems.insert(food.id)
                await viewModel.addEntry(
                    food: foodItem,
                    quantity: food.servingSizeG,
                    mealType: viewModel.selectedMealType
                )
            }
        }
    }

    private func resetScanner() {
        selectedImage = nil
        scannedFoods = []
        errorMessage = nil
        isAnalyzing = false
        addedItems = []
        imagePickerItem = nil
    }

    // MARK: - Scan Limit Badge

    @ViewBuilder
    private var scanLimitBadge: some View {
        if let remaining = ScanUsageTracker.scansRemaining(isPremium: isPremium) {
            HStack(spacing: 6) {
                Image(systemName: remaining > 0 ? "sparkles" : "lock.fill")
                    .font(.caption2.bold())
                Text(remaining > 0
                     ? String(localized: "\(remaining) scan\(remaining == 1 ? "" : "s") left today")
                     : String(localized: "Daily limit reached"))
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(remaining > 0 ? ThemeColors.textSecondary : .orange)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(remaining > 0
                               ? ThemeColors.surfaceColor
                               : Color.orange.opacity(0.15))
            )
            .padding(.top, 4)
        }
        // Premium users: no badge shown (unlimited)
    }

    // MARK: - Helpers
    
    @ViewBuilder
    private func glowingOrb(color: Color, size: CGFloat, offset: CGSize, opacity: Double) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .blur(radius: size / 4)
            .offset(offset)
            .blendMode(.screen)
    }

    // MARK: - Scanner Corner Brackets

    private var scannerCorners: some View {
        let size: CGFloat = 130
        let cornerLength: CGFloat = 20
        let lineWidth: CGFloat = 2.5
        let color = ThemeColors.info.opacity(0.5)

        return ZStack {
            // Top-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: cornerLength))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: cornerLength, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .offset(x: -size/2, y: -size/2)

            // Top-right
            Path { p in
                p.move(to: CGPoint(x: size - cornerLength, y: 0))
                p.addLine(to: CGPoint(x: size, y: 0))
                p.addLine(to: CGPoint(x: size, y: cornerLength))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .offset(x: -size/2, y: -size/2)

            // Bottom-left
            Path { p in
                p.move(to: CGPoint(x: 0, y: size - cornerLength))
                p.addLine(to: CGPoint(x: 0, y: size))
                p.addLine(to: CGPoint(x: cornerLength, y: size))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .offset(x: -size/2, y: -size/2)

            // Bottom-right
            Path { p in
                p.move(to: CGPoint(x: size - cornerLength, y: size))
                p.addLine(to: CGPoint(x: size, y: size))
                p.addLine(to: CGPoint(x: size, y: size - cornerLength))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .offset(x: -size/2, y: -size/2)
        }
    }
}

// MARK: - Camera Picker (UIKit Wrapper)

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
