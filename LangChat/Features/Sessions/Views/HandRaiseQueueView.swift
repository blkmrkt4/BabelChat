import UIKit

protocol HandRaiseQueueDelegate: AnyObject {
    func didPromoteUser(userId: String)
}

class HandRaiseQueueView: UIViewController {

    weak var delegate: HandRaiseQueueDelegate?

    private let sessionId: String
    private var queue: [SessionParticipant] = []
    private let tableView = UITableView()
    private let emptyLabel = UILabel()

    init(sessionId: String) {
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "session_hand_raise_queue".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )

        setupViews()
        loadQueue()
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "QueueCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        emptyLabel.text = "session_no_raised_hands".localized
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func loadQueue() {
        Task {
            do {
                let fetched = try await SessionService.shared.getHandRaiseQueue(sessionId: sessionId)
                await MainActor.run {
                    self.queue = fetched
                    self.emptyLabel.isHidden = !fetched.isEmpty
                    self.tableView.isHidden = fetched.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                print("Failed to load hand raise queue: \(error)")
            }
        }
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension HandRaiseQueueView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queue.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QueueCell", for: indexPath)
        let participant = queue[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = participant.user?.firstName ?? "User"

        if let raisedAt = participant.handRaisedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            content.secondaryText = formatter.localizedString(for: raisedAt, relativeTo: Date())
        }

        content.image = UIImage(systemName: "hand.raised.fill")
        content.imageProperties.tintColor = .systemYellow

        cell.contentConfiguration = content

        // Add promote button
        let promoteButton = UIButton(type: .system)
        promoteButton.setTitle("session_promote".localized, for: .normal)
        promoteButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        promoteButton.tag = indexPath.row
        promoteButton.addTarget(self, action: #selector(promoteTapped(_:)), for: .touchUpInside)
        cell.accessoryView = promoteButton
        promoteButton.sizeToFit()

        return cell
    }
}

// MARK: - UITableViewDelegate
extension HandRaiseQueueView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Actions
extension HandRaiseQueueView {
    @objc private func promoteTapped(_ sender: UIButton) {
        let participant = queue[sender.tag]
        delegate?.didPromoteUser(userId: participant.userId)
        dismiss(animated: true)
    }
}
