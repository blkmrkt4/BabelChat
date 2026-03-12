import UIKit

protocol CreateSessionDelegate: AnyObject {
    func didCreateSession(_ session: Session)
}

class CreateSessionViewController: UIViewController {

    weak var delegate: CreateSessionDelegate?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let titleField = UITextField()
    private let goalField = UITextField()
    private let nativeLanguageButton = UIButton(type: .system)
    private let learningLanguageButton = UIButton(type: .system)
    private let openSessionToggle = UISwitch()
    private let scheduleSegment = UISegmentedControl(items: ["session_now".localized, "session_schedule".localized])
    private let datePicker = UIDatePicker()
    private let addParticipantButton = UIButton(type: .system)
    private let inviteesStack = UIStackView()
    private let createButton = UIButton(type: .system)

    // MARK: - State
    private var selectedNativeLanguage: Language?
    private var selectedLearningLanguage: Language?
    private var invitees: [(user: User, role: SessionRole)] = []
    private static let maxInvitees = 3

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()

        // Default to user's languages
        Task {
            if let profile = try? await SupabaseService.shared.getCurrentProfile() {
                await MainActor.run {
                    if let nativeLang = Language.from(name: profile.nativeLanguage ?? "") {
                        self.selectedNativeLanguage = nativeLang
                    }
                    if let learningLangs = profile.learningLanguages, let first = learningLangs.first,
                       let lang = Language.from(name: first) {
                        self.selectedLearningLanguage = lang
                    }
                    self.updateLanguageButtons()
                }
            }
        }
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "session_create_title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupViews() {
        view.backgroundColor = .systemGroupedBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        contentStack.spacing = 16

        // Title field
        addSectionLabel("session_title_label".localized)
        titleField.placeholder = "session_title_placeholder".localized
        titleField.borderStyle = .roundedRect
        titleField.font = .systemFont(ofSize: 16)
        contentStack.addArrangedSubview(titleField)

        // Goal field
        addSectionLabel("session_goal_label".localized)
        goalField.placeholder = "session_goal_placeholder".localized
        goalField.borderStyle = .roundedRect
        goalField.font = .systemFont(ofSize: 16)
        contentStack.addArrangedSubview(goalField)

        // Language pair (side by side)
        addSectionLabel("session_language_pair".localized)

        let languageRow = UIStackView()
        languageRow.axis = .horizontal
        languageRow.spacing = 12
        languageRow.distribution = .fillEqually

        nativeLanguageButton.setTitle("session_select_native".localized, for: .normal)
        nativeLanguageButton.contentHorizontalAlignment = .center
        nativeLanguageButton.titleLabel?.font = .systemFont(ofSize: 16)
        nativeLanguageButton.backgroundColor = .secondarySystemBackground
        nativeLanguageButton.layer.cornerRadius = 10
        nativeLanguageButton.addTarget(self, action: #selector(selectNativeLanguage), for: .touchUpInside)
        nativeLanguageButton.translatesAutoresizingMaskIntoConstraints = false
        nativeLanguageButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        learningLanguageButton.setTitle("session_select_learning".localized, for: .normal)
        learningLanguageButton.contentHorizontalAlignment = .center
        learningLanguageButton.titleLabel?.font = .systemFont(ofSize: 16)
        learningLanguageButton.backgroundColor = .secondarySystemBackground
        learningLanguageButton.layer.cornerRadius = 10
        learningLanguageButton.addTarget(self, action: #selector(selectLearningLanguage), for: .touchUpInside)

        languageRow.addArrangedSubview(nativeLanguageButton)
        languageRow.addArrangedSubview(learningLanguageButton)
        contentStack.addArrangedSubview(languageRow)

        // Open session toggle (no section label)
        let toggleRow = UIStackView()
        toggleRow.axis = .horizontal
        toggleRow.spacing = 12
        let toggleLabel = UILabel()
        toggleLabel.text = "session_open_description".localized
        toggleLabel.font = .systemFont(ofSize: 14)
        toggleLabel.textColor = .secondaryLabel
        toggleLabel.numberOfLines = 0
        toggleRow.addArrangedSubview(toggleLabel)
        toggleRow.addArrangedSubview(openSessionToggle)
        contentStack.addArrangedSubview(toggleRow)

        // Schedule (no section label)
        scheduleSegment.selectedSegmentIndex = 0
        scheduleSegment.addTarget(self, action: #selector(scheduleChanged), for: .valueChanged)
        contentStack.addArrangedSubview(scheduleSegment)

        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())
        datePicker.date = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        datePicker.maximumDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        datePicker.minuteInterval = 5
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.isHidden = true
        contentStack.addArrangedSubview(datePicker)

        // Invitees list + add button (no section label)
        inviteesStack.axis = .vertical
        inviteesStack.spacing = 8
        contentStack.addArrangedSubview(inviteesStack)

        addParticipantButton.setTitle("session_add_participant".localized, for: .normal)
        addParticipantButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        addParticipantButton.contentHorizontalAlignment = .leading
        addParticipantButton.titleLabel?.font = .systemFont(ofSize: 16)
        addParticipantButton.addTarget(self, action: #selector(addParticipantTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(addParticipantButton)

        // Create button
        createButton.setTitle("session_create_button".localized, for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .systemBlue
        createButton.layer.cornerRadius = 12
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        contentStack.addArrangedSubview(createButton)
    }

    private func addSectionLabel(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        contentStack.addArrangedSubview(label)
    }

    private func updateLanguageButtons() {
        if let lang = selectedNativeLanguage {
            nativeLanguageButton.setTitle("\(lang.flag) \(lang.name)", for: .normal)
        }
        if let lang = selectedLearningLanguage {
            learningLanguageButton.setTitle("\(lang.flag) \(lang.name)", for: .normal)
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func scheduleChanged() {
        datePicker.isHidden = scheduleSegment.selectedSegmentIndex == 0
    }

    @objc private func selectNativeLanguage() {
        showLanguagePicker { [weak self] language in
            self?.selectedNativeLanguage = language
            self?.updateLanguageButtons()
        }
    }

    @objc private func selectLearningLanguage() {
        showLanguagePicker { [weak self] language in
            self?.selectedLearningLanguage = language
            self?.updateLanguageButtons()
        }
    }

    private func showLanguagePicker(completion: @escaping (Language) -> Void) {
        let alert = UIAlertController(title: "session_select_language".localized, message: nil, preferredStyle: .actionSheet)
        for language in Language.allCases {
            alert.addAction(UIAlertAction(title: "\(language.flag) \(language.name)", style: .default) { _ in
                completion(language)
            })
        }
        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(alert, animated: true)
    }

    @objc private func createTapped() {
        guard let nativeLang = selectedNativeLanguage,
              let learningLang = selectedLearningLanguage else {
            showAlert(title: "session_error_title".localized, message: "session_select_languages_error".localized)
            return
        }

        let languagePair = SessionLanguagePair(native: nativeLang.name, learning: learningLang.name)
        let title = titleField.text?.isEmpty == false ? titleField.text : nil
        let goal = goalField.text?.isEmpty == false ? goalField.text : nil
        let isOpen = openSessionToggle.isOn
        let scheduledAt = scheduleSegment.selectedSegmentIndex == 1 ? datePicker.date : nil

        createButton.isEnabled = false
        createButton.setTitle("common_loading".localized, for: .normal)

        let inviteeList = invitees.map { (userId: $0.user.id, role: $0.role) }

        Task {
            do {
                let session = try await SessionService.shared.createSession(
                    title: title,
                    goal: goal,
                    languagePair: languagePair,
                    isOpen: isOpen,
                    scheduledAt: scheduledAt,
                    invitees: inviteeList
                )

                await MainActor.run {
                    self.dismiss(animated: true) {
                        self.delegate?.didCreateSession(session)
                    }
                }
            } catch {
                await MainActor.run {
                    self.createButton.isEnabled = true
                    self.createButton.setTitle("session_create_button".localized, for: .normal)
                    self.showAlert(title: "session_error_title".localized, message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func addParticipantTapped() {
        guard invitees.count < Self.maxInvitees else {
            showAlert(title: "session_error_title".localized, message: "session_max_participants_error".localized)
            return
        }

        let excludedIds = invitees.map { $0.user.id }
        let selectVC = SelectMatchViewController(excludedUserIds: excludedIds)
        selectVC.onSelectUser = { [weak self] user in
            self?.showRolePicker(for: user)
        }
        let nav = UINavigationController(rootViewController: selectVC)
        present(nav, animated: true)
    }

    private func showRolePicker(for user: User) {
        let pickerVC = UIViewController()
        pickerVC.view.backgroundColor = .systemGroupedBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(stack)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = String(format: "session_select_role_message".localized, user.firstName)
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        stack.addArrangedSubview(titleLabel)

        // Co-Host card
        let coHostCard = createRoleCard(
            roleName: "session_role_co_host".localized,
            description: "session_role_cohost_desc".localized,
            iconName: "person.2.fill"
        )
        coHostCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(coHostCardTapped)))
        coHostCard.accessibilityLabel = "coHost"
        stack.addArrangedSubview(coHostCard)

        // Participant card
        let speakerCard = createRoleCard(
            roleName: "session_role_speaker".localized,
            description: "session_role_speaker_desc".localized,
            iconName: "video.fill"
        )
        speakerCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(participantCardTapped)))
        speakerCard.accessibilityLabel = "participant"
        stack.addArrangedSubview(speakerCard)

        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("common_cancel".localized, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.addTarget(self, action: #selector(rolePickerCancelled), for: .touchUpInside)
        stack.addArrangedSubview(cancelButton)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pickerVC.view.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: pickerVC.view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor, constant: -20),
        ])

        // Store user reference for callback
        pendingRoleUser = user

        let nav = UINavigationController(rootViewController: pickerVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private var pendingRoleUser: User?

    private func createRoleCard(roleName: String, description: String, iconName: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 14
        card.isUserInteractionEnabled = true

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(icon)

        let nameLabel = UILabel()
        nameLabel.text = roleName
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(descLabel)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])

        return card
    }

    @objc private func coHostCardTapped() {
        guard let user = pendingRoleUser else { return }
        dismiss(animated: true) { [weak self] in
            self?.addInvitee(user: user, role: .coHost)
            self?.pendingRoleUser = nil
        }
    }

    @objc private func participantCardTapped() {
        guard let user = pendingRoleUser else { return }
        dismiss(animated: true) { [weak self] in
            self?.addInvitee(user: user, role: .rotatingSpeaker)
            self?.pendingRoleUser = nil
        }
    }

    @objc private func rolePickerCancelled() {
        pendingRoleUser = nil
        dismiss(animated: true)
    }

    private func addInvitee(user: User, role: SessionRole) {
        invitees.append((user: user, role: role))
        updateInviteesDisplay()
    }

    private func updateInviteesDisplay() {
        inviteesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, invitee) in invitees.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.alignment = .center

            let nameLabel = UILabel()
            nameLabel.text = "\(invitee.user.firstName) — \(invitee.role.displayName)"
            nameLabel.font = .systemFont(ofSize: 15)
            nameLabel.textColor = .label

            let removeButton = UIButton(type: .system)
            removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            removeButton.tintColor = .systemRed
            removeButton.tag = index
            removeButton.addTarget(self, action: #selector(removeInvitee(_:)), for: .touchUpInside)

            row.addArrangedSubview(nameLabel)
            row.addArrangedSubview(removeButton)

            inviteesStack.addArrangedSubview(row)
        }

        addParticipantButton.isHidden = invitees.count >= Self.maxInvitees
    }

    @objc private func removeInvitee(_ sender: UIButton) {
        let index = sender.tag
        guard index < invitees.count else { return }
        invitees.remove(at: index)
        updateInviteesDisplay()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default))
        present(alert, animated: true)
    }
}
