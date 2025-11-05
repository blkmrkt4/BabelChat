import UIKit

class PhoneVerificationViewController: BaseOnboardingViewController {

    // MARK: - UI Components
    private let codeStackView = UIStackView()
    private var codeFields: [UITextField] = []
    private let resendButton = UIButton(type: .system)
    private let timerLabel = UILabel()

    // MARK: - Properties
    var phoneNumber: String?
    private var timer: Timer?
    private var secondsRemaining = 60

    // MARK: - Lifecycle
    override func configure() {
        step = .phoneVerification
        setTitle("Enter verification code",
                subtitle: "We sent a 6-digit code to \(phoneNumber ?? "your phone")")
        setupCodeInput()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Setup
    private func setupCodeInput() {
        // Code input stack
        codeStackView.axis = .horizontal
        codeStackView.distribution = .fillEqually
        codeStackView.spacing = 12
        contentView.addSubview(codeStackView)

        // Create 6 code fields
        for i in 0..<6 {
            let field = createCodeField(tag: i)
            codeFields.append(field)
            codeStackView.addArrangedSubview(field)
        }

        // Resend button
        resendButton.setTitle("Resend code", for: .normal)
        resendButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        resendButton.setTitleColor(.systemBlue, for: .normal)
        resendButton.isEnabled = false
        resendButton.alpha = 0.5
        resendButton.addTarget(self, action: #selector(resendCodeTapped), for: .touchUpInside)
        contentView.addSubview(resendButton)

        // Timer label
        timerLabel.text = "Resend available in \(secondsRemaining)s"
        timerLabel.font = .systemFont(ofSize: 14, weight: .regular)
        timerLabel.textColor = .secondaryLabel
        timerLabel.textAlignment = .center
        contentView.addSubview(timerLabel)

        // Layout
        codeStackView.translatesAutoresizingMaskIntoConstraints = false
        resendButton.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Code stack
            codeStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            codeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            codeStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            codeStackView.heightAnchor.constraint(equalToConstant: 56),

            // Resend button
            resendButton.topAnchor.constraint(equalTo: codeStackView.bottomAnchor, constant: 40),
            resendButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Timer label
            timerLabel.topAnchor.constraint(equalTo: resendButton.bottomAnchor, constant: 8),
            timerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            timerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Auto-focus first field
        codeFields.first?.becomeFirstResponder()
    }

    private func createCodeField(tag: Int) -> UITextField {
        let field = UITextField()
        field.tag = tag
        field.font = .systemFont(ofSize: 24, weight: .semibold)
        field.textColor = .label
        field.textAlignment = .center
        field.keyboardType = .numberPad
        field.textContentType = .oneTimeCode
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.systemGray4.cgColor
        field.layer.cornerRadius = 8
        field.delegate = self
        field.addTarget(self, action: #selector(codeFieldChanged(_:)), for: .editingChanged)
        return field
    }

    // MARK: - Timer
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    private func updateTimer() {
        secondsRemaining -= 1

        if secondsRemaining > 0 {
            timerLabel.text = "Resend available in \(secondsRemaining)s"
        } else {
            timer?.invalidate()
            timer = nil
            timerLabel.text = "Didn't receive the code?"
            resendButton.isEnabled = true
            resendButton.alpha = 1.0
        }
    }

    // MARK: - Actions
    @objc private func codeFieldChanged(_ textField: UITextField) {
        // Move to next field if current has a value
        if let text = textField.text, !text.isEmpty, textField.tag < 5 {
            codeFields[textField.tag + 1].becomeFirstResponder()
        }

        // Check if all fields are filled
        checkCode()
    }

    @objc private func resendCodeTapped() {
        // Reset timer
        secondsRemaining = 60
        resendButton.isEnabled = false
        resendButton.alpha = 0.5
        startTimer()

        // Clear fields
        codeFields.forEach { $0.text = "" }
        codeFields.first?.becomeFirstResponder()

        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func checkCode() {
        let code = codeFields.map { $0.text ?? "" }.joined()
        let isComplete = code.count == 6

        updateContinueButton(enabled: isComplete)

        if isComplete {
            // Auto-continue for smoother UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.verifyCode()
            }
        }
    }

    private func verifyCode() {
        let code = codeFields.map { $0.text ?? "" }.joined()

        // For demo, accept any 6-digit code
        // In production, verify with backend
        if code.count == 6 {
            delegate?.didCompleteStep(withData: code)
        }
    }

    override func continueButtonTapped() {
        verifyCode()
    }
}

// MARK: - UITextFieldDelegate
extension PhoneVerificationViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Get current text safely
        let currentText = textField.text ?? ""

        // Validate range before using it
        guard range.location >= 0,
              range.location <= currentText.count,
              range.location + range.length <= currentText.count else {
            return false
        }

        // Only allow numbers
        if !string.isEmpty && !string.allSatisfy({ $0.isNumber }) {
            return false
        }

        // Calculate new text safely
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)

        // Limit to 1 character
        if newText.count > 1 {
            return false
        }

        // Handle backspace
        if string.isEmpty && currentText.isEmpty && textField.tag > 0 {
            codeFields[textField.tag - 1].becomeFirstResponder()
        }

        return true
    }
}