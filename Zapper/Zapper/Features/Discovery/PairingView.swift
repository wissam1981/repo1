import SwiftUI

struct PairingView: View {
    @Bindable var viewModel: DiscoveryViewModel
    @FocusState private var pinFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Text("📺")
                        .font(.system(size: 40))
                    Text("↔")
                        .foregroundStyle(ZapperTheme.Colors.primary)
                    Text("📱")
                        .font(.system(size: 40))
                }

                Text("Pairing Required")
                    .font(ZapperTheme.Typography.headline(22, weight: .bold))
                    .foregroundStyle(ZapperTheme.Colors.onSurface)

                Text("Enter the code shown on your TV")
                    .font(ZapperTheme.Typography.body(14))
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
            }
            .padding(.top, 40)

            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    let char = pinCharacter(at: index)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0x1F1F25, opacity: 0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    index == viewModel.pairingPIN.count
                                        ? ZapperTheme.Colors.primary.opacity(0.5)
                                        : ZapperTheme.Colors.outlineVariant.opacity(0.15),
                                    lineWidth: 1.5
                                )
                        )
                        .overlay(
                            Text(char)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(ZapperTheme.Colors.onSurface)
                        )
                        .frame(width: 44, height: 56)
                }
            }

            TextField("", text: $viewModel.pairingPIN)
                .keyboardType(.numberPad)
                .focused($pinFocused)
                .frame(width: 0, height: 0)
                .opacity(0)
                .onChange(of: viewModel.pairingPIN) { _, newValue in
                    viewModel.pairingPIN = String(newValue.prefix(6))
                }

            if let error = viewModel.pairingError {
                Text(error)
                    .font(ZapperTheme.Typography.body(13))
                    .foregroundStyle(ZapperTheme.Colors.error)
            }

            Button {
                viewModel.submitPIN()
            } label: {
                Text("Connect")
                    .font(ZapperTheme.Typography.label(15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [ZapperTheme.Colors.primaryContainer, Color(hex: 0x1D4ED8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: ZapperTheme.Colors.primaryContainer.opacity(0.3), radius: 12)
            }
            .jewelButton()
            .disabled(viewModel.pairingPIN.count < 4)
            .padding(.horizontal)

            Spacer()
        }
        .background(ZapperTheme.Colors.surface.ignoresSafeArea())
        .onAppear { pinFocused = true }
    }

    private func pinCharacter(at index: Int) -> String {
        let pin = viewModel.pairingPIN
        guard index < pin.count else { return "" }
        return String(pin[pin.index(pin.startIndex, offsetBy: index)])
    }
}
