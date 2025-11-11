import SwiftUI

struct OnboardingView: View {
    @State private var serverUrl: String = ""
    @State private var token: String = ""
    @State private var isValidating: Bool = false
    @State private var errorMessage: String? = nil
    @FocusState private var focusedField: Field?

    let onComplete: (String, String) -> Void
    var onClose: (() -> Void)? = nil

    enum Field: Hashable {
        case serverUrl
        case token
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                            .resizable()
                            .frame(width: 48, height: 48)
                            .accessibilityLabel("Plex application icon")

                        Text("Plex Desktop Widget")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Let's get you set up!")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Plex Desktop Widget. Let's get you set up!")

                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("1")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 24, height: 24)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 229/255, green: 160/255, blue: 13/255),
                                            Color(red: 204/255, green: 123/255, blue: 2/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Get your Plex Token")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.95))

                                VStack(alignment: .leading, spacing: 4) {
                                    BulletPoint(text: "Open the Plex Desktop or Web App")
                                    BulletPoint(text: "Play any item")
                                    BulletPoint(text: "Click the vertical dots (⋮) then 'Get Info'")
                                    BulletPoint(text: "Click 'View XML'")
                                    BulletPoint(text: "Copy the X-Plex-Token value (it's at the end of the URL)")
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step 1: Get your Plex Token. Open the Plex Desktop or Web App, Play any item, Click the vertical dots then Get Info, Click View XML, Copy the X-Plex-Token value at the end of the URL")

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/")!)
                    }) {
                        Text("How to find your Plex Token")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 229/255, green: 160/255, blue: 13/255))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 36)
                    .accessibilityLabel("Open support article: How to find your Plex Token")

                    InstructionStep(
                        number: 2,
                        title: "Enter your Plex Server URL",
                        description: "Usually http://localhost:32400 or your server's IP address"
                    )
                }

                // Input Fields
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plex Token")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))

                        TransparentSecureField(
                            placeholder: "Your X-Plex-Token",
                            text: $token,
                            isFocused: focusedField == .token
                        )
                        .padding(12)
                        .frame(height: 44)
                        .background(
                            ZStack {
                                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                                Color.black.opacity(0.4)
                            }
                            .cornerRadius(8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedField == .token ? Color(red: 229/255, green: 160/255, blue: 13/255).opacity(0.5) : Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .focused($focusedField, equals: .token)
                        .accessibilityLabel("Plex Token")
                        .accessibilityHint("Enter your X-Plex-Token from the Plex app")
                        .onSubmit {
                            focusedField = .serverUrl
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server URL")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))

                        TransparentTextField(
                            placeholder: "http://localhost:32400",
                            text: $serverUrl,
                            isFocused: focusedField == .serverUrl
                        )
                        .padding(12)
                        .frame(height: 44)
                        .background(
                            ZStack {
                                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                                Color.black.opacity(0.4)
                            }
                            .cornerRadius(8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedField == .serverUrl ? Color(red: 229/255, green: 160/255, blue: 13/255).opacity(0.5) : Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .focused($focusedField, equals: .serverUrl)
                        .accessibilityLabel("Server URL")
                        .accessibilityHint("Enter your Plex server URL, usually http://localhost:32400")
                        .onSubmit {
                            if isFormValid {
                                validateAndSave()
                            }
                        }
                    }
                }

                // Error message
                if let errorMessage = errorMessage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(Color(red: 255/255, green: 100/255, blue: 100/255))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))

                            Text("Please check your server URL and token, then try again.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(errorMessage). Please check your server URL and token, then try again.")
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                // Continue Button
                Button(action: validateAndSave) {
                    HStack(spacing: 8) {
                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            Text("Validating...")
                        } else {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                    .background(
                        Group {
                            if isFormValid {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 229/255, green: 160/255, blue: 13/255),
                                        Color(red: 204/255, green: 123/255, blue: 2/255)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.25)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    )
                    .cornerRadius(10)
                    .shadow(color: isFormValid ? Color.black.opacity(0.15) : .clear, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isFormValid || isValidating)
                .onHover { isHovering in
                    if isHovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .padding(.top, 8)
                .keyboardShortcut(.return, modifiers: [])
                .accessibilityLabel(isValidating ? "Validating connection" : "Continue")
                .accessibilityHint(isFormValid ? "Press to validate your Plex server credentials" : "Enter server URL and token to continue")
            }
            .padding(20)
        }
        .frame(width: 520, height: 600)
        .background(
            Color(red: 13/255, green: 13/255, blue: 13/255).opacity(0.85)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )

            // Close button (overlay on top-right)
            Button(action: {
                onClose?()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                if isHovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .padding([.top, .trailing], 16)
            .accessibilityLabel("Close")
        }
    }

    private var isFormValid: Bool {
        !serverUrl.trimmingCharacters(in: .whitespaces).isEmpty &&
        !token.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidUrl(serverUrl.trimmingCharacters(in: .whitespaces)) &&
        isValidToken(token.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Security Validation

    /// Validates URL format - only allows http/https protocols with valid format
    private func isValidUrl(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }

        // Must have a scheme
        guard let scheme = url.scheme?.lowercased() else { return false }

        // Only allow http and https protocols
        guard scheme == "http" || scheme == "https" else { return false }

        // Must have a host
        guard let host = url.host, !host.isEmpty else { return false }

        // Additional validation: host should not contain spaces or invalid characters
        let hostCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
        guard host.unicodeScalars.allSatisfy({ hostCharacterSet.contains($0) }) else {
            return false
        }

        return true
    }

    /// Validates Plex token format - alphanumeric, 15-25 characters
    private func isValidToken(_ tokenString: String) -> Bool {
        // Plex tokens are typically 20 characters, alphanumeric
        // Allow range of 15-25 to accommodate potential variations
        let tokenLength = tokenString.count
        guard tokenLength >= 15 && tokenLength <= 25 else { return false }

        // Must be alphanumeric only
        let alphanumericSet = CharacterSet.alphanumerics
        return tokenString.unicodeScalars.allSatisfy { alphanumericSet.contains($0) }
    }

    private func validateAndSave() {
        guard isFormValid else { return }

        // Dismiss keyboard
        focusedField = nil

        // Clear previous error with animation
        withAnimation(.easeOut(duration: 0.2)) {
            errorMessage = nil
        }
        isValidating = true

        // Clean up inputs
        let cleanUrl = serverUrl.trimmingCharacters(in: .whitespaces)
        let cleanToken = token.trimmingCharacters(in: .whitespaces)

        // CRITICAL FIX: Wrap async task to stabilize autorelease pool behavior.
        // This prevents memory corruption when async task's autorelease pool
        // interferes with NSHostingView's lifecycle management.
        autoreleasepool {
            Task {
                print("DEBUG Onboarding: Testing connection to \(cleanUrl)")

                // Create test API instance and validate connection
                // Network I/O happens on background thread
                let testResult = await validatePlexConnection(serverUrl: cleanUrl, token: cleanToken)

                print("DEBUG Onboarding: Validation result - success: \(testResult.success), error: \(testResult.error ?? "nil")")

                // Now switch to MainActor for UI updates only
                await MainActor.run {
                    if let error = testResult.error {
                        // Connection failed - show error with animation
                        print("DEBUG Onboarding: Connection failed with error: \(error)")
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            errorMessage = error
                            isValidating = false
                        }
                    } else {
                        // Success! Save the config
                        print("DEBUG Onboarding: Connection successful, saving config")
                        if ConfigManager.shared.saveConfig(serverUrl: cleanUrl, token: cleanToken) {
                            // Call onComplete BEFORE setting isValidating = false
                            // This ensures proper cleanup order when the window closes
                            onComplete(cleanUrl, cleanToken)
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                errorMessage = "Failed to save configuration"
                                isValidating = false
                            }
                        }
                    }
                }
            }
        }
    }

    /// Validates Plex server connection by performing a test API call
    /// Returns a tuple with success status and optional error message
    /// NOTE: This function performs network I/O and should NOT run on MainActor
    private func validatePlexConnection(serverUrl: String, token: String) async -> (success: Bool, error: String?) {
        guard let url = URL(string: "\(serverUrl)/status/sessions") else {
            return (false, "Invalid server URL format")
        }

        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        request.setValue("plex-desktop-widget-validation", forHTTPHeaderField: "X-Plex-Client-Identifier")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0

        do {
            // Perform network call on background thread (not MainActor)
            // This prevents crashes during URLSession SSL handshake and DNS resolution
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Invalid response from server")
            }

            switch httpResponse.statusCode {
            case 200:
                return (true, nil)
            case 401:
                return (false, "Invalid Plex token - authentication failed")
            case 404:
                return (false, "Server endpoint not found - check your server URL")
            case 500...599:
                return (false, "Server error (\(httpResponse.statusCode))")
            default:
                return (false, "Unexpected server response (\(httpResponse.statusCode))")
            }
        } catch let error as NSError {
            // Handle specific network errors
            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorTimedOut:
                    return (false, "Connection timed out - server may be unreachable")
                case NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost:
                    return (false, "Cannot connect to server - check URL and network")
                case NSURLErrorNetworkConnectionLost:
                    return (false, "Network connection lost")
                case NSURLErrorNotConnectedToInternet:
                    return (false, "No internet connection - check your network")
                case NSURLErrorSecureConnectionFailed:
                    return (false, "SSL connection failed - use http:// instead of https://")
                case NSURLErrorServerCertificateUntrusted:
                    return (false, "Server certificate untrusted - check server URL")
                default:
                    // Show error code for debugging
                    return (false, "Network error (code \(error.code)): \(error.localizedDescription)")
                }
            }
            return (false, "Connection failed: \(error.localizedDescription)")
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 229/255, green: 160/255, blue: 13/255),
                            Color(red: 204/255, green: 123/255, blue: 2/255)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Custom transparent text field with NSViewRepresentable
struct TransparentTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool

    func makeNSView(context: Context) -> NSTextField {
        let textField = CustomNSTextField()
        textField.stringValue = ""
        textField.placeholderString = placeholder
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.5)]
        )
        textField.isBordered = false
        textField.isBezeled = false
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 13)
        textField.delegate = context.coordinator
        textField.focusRingType = .none
        textField.drawsBackground = false
        textField.isEditable = true
        textField.isSelectable = true

        // Ensure the field editor (cell) is editable
        if let cell = textField.cell as? NSTextFieldCell {
            cell.isEditable = true
            cell.isSelectable = true
        }

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Only update if not currently editing (prevents interference with field editor)
        if nsView.currentEditor() == nil {
            nsView.stringValue = text
        }
        nsView.textColor = .white
    }

    // Custom NSTextField that accepts first responder
    class CustomNSTextField: NSTextField {
        override func becomeFirstResponder() -> Bool {
            let didBecome = super.becomeFirstResponder()
            if didBecome {
                currentEditor()?.selectedRange = NSRange(location: stringValue.count, length: 0)
            }
            return didBecome
        }

        override var acceptsFirstResponder: Bool {
            return true
        }

        override func textDidChange(_ notification: Notification) {
            super.textDidChange(notification)
            // Force redraw with white text
            textColor = .white
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TransparentTextField

        init(_ parent: TransparentTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
    }
}

// Custom transparent secure field
struct TransparentSecureField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool

    func makeNSView(context: Context) -> NSSecureTextField {
        let textField = CustomNSSecureTextField()
        textField.stringValue = ""
        textField.placeholderString = placeholder
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.5)]
        )
        textField.isBordered = false
        textField.isBezeled = false
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 13)
        textField.delegate = context.coordinator
        textField.focusRingType = .none
        textField.drawsBackground = false
        textField.isEditable = true
        textField.isSelectable = true

        // Ensure the field editor (cell) is editable
        if let cell = textField.cell as? NSSecureTextFieldCell {
            cell.isEditable = true
            cell.isSelectable = true
        }

        return textField
    }

    func updateNSView(_ nsView: NSSecureTextField, context: Context) {
        // Only update if not currently editing (prevents interference with field editor)
        if nsView.currentEditor() == nil {
            nsView.stringValue = text
        }
        nsView.textColor = .white
    }

    // Custom NSSecureTextField that accepts first responder
    class CustomNSSecureTextField: NSSecureTextField {
        override func becomeFirstResponder() -> Bool {
            let didBecome = super.becomeFirstResponder()
            if didBecome {
                currentEditor()?.selectedRange = NSRange(location: stringValue.count, length: 0)
            }
            return didBecome
        }

        override var acceptsFirstResponder: Bool {
            return true
        }

        override func textDidChange(_ notification: Notification) {
            super.textDidChange(notification)
            // Force redraw with white text
            textColor = .white
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TransparentSecureField

        init(_ parent: TransparentSecureField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSSecureTextField else { return }
            parent.text = textField.stringValue
        }
    }
}

// Wrapper to add the background styling
struct TransparentTextFieldStyled<Field: View>: View {
    let field: Field
    var isFocused: Bool

    var body: some View {
        field
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    // Backdrop blur layer
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)

                    // Darker tinted overlay
                    Color.black.opacity(0.4)
                }
                .cornerRadius(8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFocused ? Color(red: 229/255, green: 160/255, blue: 13/255).opacity(0.5) : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(color: isFocused ? Color(red: 229/255, green: 160/255, blue: 13/255).opacity(0.1) : .clear, radius: 3)
    }
}

#Preview {
    OnboardingView { serverUrl, token in
        print("Configured: \(serverUrl), \(token)")
    }
}
