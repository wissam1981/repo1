import SwiftUI

// MARK: - Sign Up View

struct SignUpView: View {
    @Bindable var viewModel: AuthViewModel
    var onSwitchToLogin: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field { case name, email, password, confirm }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                    Text("Start your fitness transformation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 16)

                // Error message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Your name", text: $viewModel.displayName)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Email Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("you@example.com", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Password Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("At least 6 characters", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Confirm Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("Re-enter password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirm)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Password match indicator
                    if !viewModel.confirmPassword.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.password == viewModel.confirmPassword
                                  ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(viewModel.password == viewModel.confirmPassword
                                 ? "Passwords match" : "Passwords don't match")
                        }
                        .font(.caption)
                        .foregroundStyle(viewModel.password == viewModel.confirmPassword ? .green : .red)
                    }
                }

                // Sign Up Button
                Button {
                    focusedField = nil
                    Task { await viewModel.signUp() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(viewModel.isLoading || !viewModel.isSignUpValid)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                }

                // Sign in with Google
                Button {
                    // This will be connected to Google SignIn SDK via AuthViewModel
                    // once the user installs the package
                    Task { await viewModel.signInWithGoogle() }
                } label: {
                    HStack {
                        Image(systemName: "g.circle.fill") // Placeholder icon
                            .foregroundColor(.red)
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))


                // Switch to Login
                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign In") {
                        viewModel.clearFields()
                        onSwitchToLogin()
                    }
                    .fontWeight(.semibold)
                }
                .font(.callout)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
