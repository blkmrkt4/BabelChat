import UIKit

// MARK: - Fluenca Brand Colors
private struct FluencaColors {
    static let primary = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)      // #FF6B6B - Warm coral
    static let secondary = UIColor(red: 0.31, green: 0.80, blue: 0.77, alpha: 1.0)   // #4ECDC4 - Teal
    static let accent = UIColor(red: 1.0, green: 0.90, blue: 0.43, alpha: 1.0)       // #FFE66D - Yellow
    static let fire = UIColor(red: 1.0, green: 0.28, blue: 0.34, alpha: 1.0)         // #FF4757 - Fire red
    static let fireGlow = UIColor(red: 1.0, green: 0.39, blue: 0.28, alpha: 1.0)     // #FF6348
    static let gold = UIColor(red: 1.0, green: 0.65, blue: 0.01, alpha: 1.0)         // #FFA502
    static let purple = UIColor(red: 0.66, green: 0.33, blue: 0.97, alpha: 1.0)      // #A855F7
    static let darkBg = UIColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0)      // #1a1a2e
    static let darkerBg = UIColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1.0)    // #0f0f1a
}

class LanguageLabViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["🔥 Streaks", "🌡️ Heat", "💓 Pulse", "⭐ Stats"])
    private let containerView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // Feature views
    private var streaksView: SparkStreaksView?
    private var heatView: FluencyHeatView?
    private var pulseView: LearningPulseView?
    private var statsView: StatsOverviewView?

    // Data
    private var labData: LanguageLabData = .loading
    private let statsService = LanguageLabStatsService.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupSegmentedControl()
        setupLoadingIndicator()
        loadData()
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadData() {
        loadingIndicator.startAnimating()
        containerView.alpha = 0.3

        Task {
            do {
                let data = try await statsService.fetchAllData()
                await MainActor.run {
                    self.labData = data
                    self.loadingIndicator.stopAnimating()
                    self.containerView.alpha = 1.0
                    self.showSelectedView(index: self.segmentedControl.selectedSegmentIndex)
                }
            } catch {
                await MainActor.run {
                    self.labData = .empty
                    self.loadingIndicator.stopAnimating()
                    self.containerView.alpha = 1.0
                    self.showSelectedView(index: self.segmentedControl.selectedSegmentIndex)
                    print("❌ Failed to load Language Lab data: \(error)")
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    private func setupViews() {
        // Dark gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            FluencaColors.darkerBg.cgColor,
            FluencaColors.darkBg.cgColor,
            FluencaColors.darkerBg.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Header
        contentView.addSubview(headerView)
        headerView.backgroundColor = .clear

        // Title with gradient effect
        titleLabel.text = "Language Lab"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        headerView.addSubview(titleLabel)

        // Subtitle
        subtitleLabel.text = "Track your fluency journey"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        headerView.addSubview(subtitleLabel)

        // Segmented control
        contentView.addSubview(segmentedControl)

        // Container for feature views
        contentView.addSubview(containerView)
        containerView.backgroundColor = .clear

        setupConstraints()
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            segmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 44),

            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 24),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 500)
        ])
    }

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        segmentedControl.selectedSegmentTintColor = FluencaColors.fire
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ], for: .normal)
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    @objc private func segmentChanged() {
        showSelectedView(index: segmentedControl.selectedSegmentIndex)
    }

    private func showSelectedView(index: Int) {
        // Remove all subviews from container
        containerView.subviews.forEach { $0.removeFromSuperview() }

        let selectedView: UIView

        switch index {
        case 0:
            // Recreate view with fresh data
            streaksView = SparkStreaksView(
                partnerStreaks: labData.partnerStreaks,
                dailyActivity: labData.dailyActivity
            )
            selectedView = streaksView!
        case 1:
            heatView = FluencyHeatView(fluencyHeat: labData.fluencyHeat)
            selectedView = heatView!
        case 2:
            pulseView = LearningPulseView(
                learningPulse: labData.learningPulse,
                dailyActivity: labData.dailyActivity
            )
            selectedView = pulseView!
        case 3:
            statsView = StatsOverviewView(wrappedStats: labData.wrappedStats)
            selectedView = statsView!
        default:
            return
        }

        containerView.addSubview(selectedView)
        selectedView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            selectedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            selectedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            selectedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            selectedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Animate transition
        selectedView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            selectedView.alpha = 1
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
}

// MARK: - Spark Streaks View (Calendar with partner streaks)
private class SparkStreaksView: UIView {

    private var partners: [(name: String, flag: String, streak: Int, photoUrl: String?)] = []
    private var dailyActivity: [DailyActivity] = []

    private var selectedPartnerIndex = 0
    private let partnerStackView = UIStackView()
    private let calendarContainer = UIView()
    private let streakBadgeView = UIView()
    private let streakCountLabel = UILabel()
    private let milestoneView = UIView()

    init(partnerStreaks: [PartnerStreak], dailyActivity: [DailyActivity]) {
        // Convert partner streaks to display format
        self.partners = partnerStreaks.isEmpty
            ? [("No partners yet", "👋", 0, nil)]
            : partnerStreaks.map { streak in
                (streak.partnerName, "🌍", streak.currentStreak, streak.partnerPhotoUrl)
            }
        self.dailyActivity = dailyActivity
        super.init(frame: .zero)
        setupViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear

        // Header with streak badge
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        addSubview(headerStack)

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = "Spark Streaks"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Keep the conversation alive"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        titleStack.addArrangedSubview(subtitleLabel)

        headerStack.addArrangedSubview(titleStack)

        // Streak badge
        streakBadgeView.backgroundColor = FluencaColors.fire
        streakBadgeView.layer.cornerRadius = 16
        headerStack.addArrangedSubview(streakBadgeView)

        let fireLabel = UILabel()
        fireLabel.text = "🔥"
        fireLabel.font = .systemFont(ofSize: 20)
        streakBadgeView.addSubview(fireLabel)

        streakCountLabel.text = "\(partners[selectedPartnerIndex].streak)"
        streakCountLabel.font = .systemFont(ofSize: 20, weight: .bold)
        streakCountLabel.textColor = .white
        streakBadgeView.addSubview(streakCountLabel)

        // Partner tabs
        partnerStackView.axis = .horizontal
        partnerStackView.spacing = 12
        partnerStackView.distribution = .fillEqually
        addSubview(partnerStackView)

        for (index, partner) in partners.enumerated() {
            let partnerView = createPartnerTab(partner: partner, index: index)
            partnerStackView.addArrangedSubview(partnerView)
        }

        // Calendar container
        calendarContainer.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        calendarContainer.layer.cornerRadius = 16
        addSubview(calendarContainer)

        createCalendarGrid()

        // Milestone view
        milestoneView.backgroundColor = FluencaColors.secondary.withAlphaComponent(0.2)
        milestoneView.layer.cornerRadius = 12
        milestoneView.layer.borderWidth = 1
        milestoneView.layer.borderColor = FluencaColors.secondary.withAlphaComponent(0.3).cgColor
        addSubview(milestoneView)

        let trophyLabel = UILabel()
        trophyLabel.text = "🏆"
        trophyLabel.font = .systemFont(ofSize: 28)
        milestoneView.addSubview(trophyLabel)

        let milestoneStack = UIStackView()
        milestoneStack.axis = .vertical
        milestoneStack.spacing = 2
        milestoneView.addSubview(milestoneStack)

        let nextLabel = UILabel()
        nextLabel.text = "Next milestone"
        nextLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nextLabel.textColor = FluencaColors.secondary
        milestoneStack.addArrangedSubview(nextLabel)

        let daysLabel = UILabel()
        let currentStreak = partners[selectedPartnerIndex].streak
        let daysToMilestone = 30 - currentStreak
        daysLabel.text = "30 Day Streak in \(daysToMilestone) days!"
        daysLabel.font = .systemFont(ofSize: 16, weight: .bold)
        daysLabel.textColor = .white
        milestoneStack.addArrangedSubview(daysLabel)

        setupConstraints(headerStack: headerStack, fireLabel: fireLabel, trophyLabel: trophyLabel, milestoneStack: milestoneStack)

        // Add pulsing animation to streak badge
        addPulseAnimation(to: streakBadgeView)
    }

    private func setupConstraints(headerStack: UIStackView, fireLabel: UILabel, trophyLabel: UILabel, milestoneStack: UIStackView) {
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        streakBadgeView.translatesAutoresizingMaskIntoConstraints = false
        fireLabel.translatesAutoresizingMaskIntoConstraints = false
        streakCountLabel.translatesAutoresizingMaskIntoConstraints = false
        partnerStackView.translatesAutoresizingMaskIntoConstraints = false
        calendarContainer.translatesAutoresizingMaskIntoConstraints = false
        milestoneView.translatesAutoresizingMaskIntoConstraints = false
        trophyLabel.translatesAutoresizingMaskIntoConstraints = false
        milestoneStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            streakBadgeView.heightAnchor.constraint(equalToConstant: 44),
            streakBadgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            fireLabel.leadingAnchor.constraint(equalTo: streakBadgeView.leadingAnchor, constant: 12),
            fireLabel.centerYAnchor.constraint(equalTo: streakBadgeView.centerYAnchor),

            streakCountLabel.leadingAnchor.constraint(equalTo: fireLabel.trailingAnchor, constant: 4),
            streakCountLabel.trailingAnchor.constraint(equalTo: streakBadgeView.trailingAnchor, constant: -12),
            streakCountLabel.centerYAnchor.constraint(equalTo: streakBadgeView.centerYAnchor),

            partnerStackView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 20),
            partnerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            partnerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            partnerStackView.heightAnchor.constraint(equalToConstant: 80),

            calendarContainer.topAnchor.constraint(equalTo: partnerStackView.bottomAnchor, constant: 20),
            calendarContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendarContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendarContainer.heightAnchor.constraint(equalToConstant: 280),

            milestoneView.topAnchor.constraint(equalTo: calendarContainer.bottomAnchor, constant: 16),
            milestoneView.leadingAnchor.constraint(equalTo: leadingAnchor),
            milestoneView.trailingAnchor.constraint(equalTo: trailingAnchor),
            milestoneView.heightAnchor.constraint(equalToConstant: 70),
            milestoneView.bottomAnchor.constraint(equalTo: bottomAnchor),

            trophyLabel.leadingAnchor.constraint(equalTo: milestoneView.leadingAnchor, constant: 16),
            trophyLabel.centerYAnchor.constraint(equalTo: milestoneView.centerYAnchor),

            milestoneStack.leadingAnchor.constraint(equalTo: trophyLabel.trailingAnchor, constant: 12),
            milestoneStack.centerYAnchor.constraint(equalTo: milestoneView.centerYAnchor)
        ])
    }

    private func createPartnerTab(partner: (name: String, flag: String, streak: Int, photoUrl: String?), index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = index == selectedPartnerIndex
            ? FluencaColors.fire.withAlphaComponent(0.3)
            : UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = index == selectedPartnerIndex ? 2 : 0
        container.layer.borderColor = FluencaColors.fire.cgColor
        container.tag = index

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(partnerTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        container.addSubview(stack)

        let flagLabel = UILabel()
        flagLabel.text = partner.flag
        flagLabel.font = .systemFont(ofSize: 24)
        stack.addArrangedSubview(flagLabel)

        let nameLabel = UILabel()
        nameLabel.text = partner.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .white
        stack.addArrangedSubview(nameLabel)

        let streakLabel = UILabel()
        streakLabel.text = "\(partner.streak) days"
        streakLabel.font = .systemFont(ofSize: 12)
        streakLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        stack.addArrangedSubview(streakLabel)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    @objc private func partnerTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        selectedPartnerIndex = view.tag

        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                view.transform = .identity
            }
        }

        // Update UI
        streakCountLabel.text = "\(partners[selectedPartnerIndex].streak)"

        // Refresh partner tabs
        for (index, subview) in partnerStackView.arrangedSubviews.enumerated() {
            subview.backgroundColor = index == selectedPartnerIndex
                ? FluencaColors.fire.withAlphaComponent(0.3)
                : UIColor.white.withAlphaComponent(0.05)
            subview.layer.borderWidth = index == selectedPartnerIndex ? 2 : 0
        }
    }

    private func createCalendarGrid() {
        let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
        let daysInMonth = 31
        let currentDay = Calendar.current.component(.day, from: Date())
        let streak = partners[selectedPartnerIndex].streak

        // Week day headers
        let weekDayStack = UIStackView()
        weekDayStack.axis = .horizontal
        weekDayStack.distribution = .fillEqually
        weekDayStack.spacing = 4
        calendarContainer.addSubview(weekDayStack)

        for day in weekDays {
            let label = UILabel()
            label.text = day
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = UIColor.white.withAlphaComponent(0.4)
            label.textAlignment = .center
            weekDayStack.addArrangedSubview(label)
        }

        // Calendar grid
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.distribution = .fillEqually
        gridStack.spacing = 4
        calendarContainer.addSubview(gridStack)

        var dayIndex = 0
        for _ in 0..<5 { // 5 weeks
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4

            for _ in 0..<7 {
                dayIndex += 1
                if dayIndex <= daysInMonth {
                    let dayView = createDayView(day: dayIndex, currentDay: currentDay, streak: streak)
                    rowStack.addArrangedSubview(dayView)
                } else {
                    let emptyView = UIView()
                    rowStack.addArrangedSubview(emptyView)
                }
            }

            gridStack.addArrangedSubview(rowStack)
        }

        weekDayStack.translatesAutoresizingMaskIntoConstraints = false
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            weekDayStack.topAnchor.constraint(equalTo: calendarContainer.topAnchor, constant: 16),
            weekDayStack.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor, constant: 12),
            weekDayStack.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor, constant: -12),
            weekDayStack.heightAnchor.constraint(equalToConstant: 20),

            gridStack.topAnchor.constraint(equalTo: weekDayStack.bottomAnchor, constant: 8),
            gridStack.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor, constant: 12),
            gridStack.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor, constant: -12),
            gridStack.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor, constant: -16)
        ])
    }

    private func createDayView(day: Int, currentDay: Int, streak: Int) -> UIView {
        let container = UIView()
        let isActive = day <= currentDay && day > currentDay - streak
        let isToday = day == currentDay

        container.backgroundColor = isActive
            ? FluencaColors.fire.withAlphaComponent(0.3 + CGFloat.random(in: 0...0.3))
            : UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 8

        if isToday {
            container.layer.borderWidth = 2
            container.layer.borderColor = FluencaColors.secondary.cgColor
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        container.addSubview(stack)

        let dayLabel = UILabel()
        dayLabel.text = "\(day)"
        dayLabel.font = .systemFont(ofSize: 14, weight: isActive ? .semibold : .regular)
        dayLabel.textColor = isActive ? .white : UIColor.white.withAlphaComponent(0.3)
        stack.addArrangedSubview(dayLabel)

        if isActive {
            let fireLabel = UILabel()
            fireLabel.text = "🔥"
            fireLabel.font = .systemFont(ofSize: 10)
            stack.addArrangedSubview(fireLabel)
        }

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func addPulseAnimation(to view: UIView) {
        let pulseAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 0.8
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity

        view.layer.shadowColor = FluencaColors.fire.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.5
        view.layer.add(pulseAnimation, forKey: "pulse")
    }
}

// MARK: - Fluency Heat View (Thermometer)
private class FluencyHeatView: UIView {

    private let temperature: CGFloat
    private let trend: FluencyHeatData.Trend
    private let weeklyAverage: Double
    private let monthlyAverage: Double

    init(fluencyHeat: FluencyHeatData) {
        self.temperature = CGFloat(fluencyHeat.currentTemperature)
        self.trend = fluencyHeat.trend
        self.weeklyAverage = fluencyHeat.weeklyAverage
        self.monthlyAverage = fluencyHeat.monthlyAverage
        super.init(frame: .zero)
        setupViews()
    }

    override init(frame: CGRect) {
        self.temperature = 0
        self.trend = .stable
        self.weeklyAverage = 0
        self.monthlyAverage = 0
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.text = "Fluency Heat"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your conversation activity"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        subtitleLabel.textAlignment = .center
        addSubview(subtitleLabel)

        // Thermometer container
        let thermometerContainer = UIView()
        thermometerContainer.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        thermometerContainer.layer.cornerRadius = 30
        addSubview(thermometerContainer)

        // Mercury fill
        let mercuryView = UIView()
        mercuryView.layer.cornerRadius = 22
        mercuryView.clipsToBounds = true
        thermometerContainer.addSubview(mercuryView)

        // Gradient for mercury
        let mercuryGradient = CAGradientLayer()
        mercuryGradient.colors = [
            FluencaColors.accent.cgColor,
            FluencaColors.primary.cgColor
        ]
        mercuryGradient.startPoint = CGPoint(x: 0.5, y: 1)
        mercuryGradient.endPoint = CGPoint(x: 0.5, y: 0)
        mercuryView.layer.addSublayer(mercuryGradient)

        // Thermometer bulb
        let bulbView = UIView()
        bulbView.backgroundColor = temperature > 50 ? FluencaColors.primary : FluencaColors.secondary
        bulbView.layer.cornerRadius = 40
        addSubview(bulbView)

        // Emoji in bulb
        let emojiLabel = UILabel()
        emojiLabel.text = temperature >= 75 ? "🔥" : temperature >= 50 ? "😎" : temperature >= 25 ? "😊" : "🥶"
        emojiLabel.font = .systemFont(ofSize: 32)
        bulbView.addSubview(emojiLabel)

        // Milestones
        let milestones: [(temp: CGFloat, label: String, emoji: String)] = [
            (0, "Ice Cold", "🥶"),
            (25, "Warming Up", "😊"),
            (50, "Getting Hot", "😎"),
            (75, "On Fire", "🔥"),
            (100, "Native Heat", "🌟")
        ]

        // Status card
        let statusCard = UIView()
        statusCard.backgroundColor = FluencaColors.accent.withAlphaComponent(0.2)
        statusCard.layer.cornerRadius = 16
        statusCard.layer.borderWidth = 1
        statusCard.layer.borderColor = FluencaColors.accent.withAlphaComponent(0.4).cgColor
        addSubview(statusCard)

        let statusStack = UIStackView()
        statusStack.axis = .vertical
        statusStack.alignment = .center
        statusStack.spacing = 4
        statusCard.addSubview(statusStack)

        let statusLabel = UILabel()
        let statusText: String
        if temperature >= 75 { statusText = "On Fire!" }
        else if temperature >= 50 { statusText = "Getting Hot" }
        else if temperature >= 25 { statusText = "Warming Up" }
        else { statusText = "Ice Cold" }
        statusLabel.text = statusText
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = FluencaColors.accent
        statusStack.addArrangedSubview(statusLabel)

        let tempLabel = UILabel()
        tempLabel.text = "\(Int(temperature))°"
        tempLabel.font = .systemFont(ofSize: 40, weight: .bold)
        tempLabel.textColor = .white
        statusStack.addArrangedSubview(tempLabel)

        let changeLabel = UILabel()
        let trendText: String
        // Show appropriate message based on temperature
        if temperature == 0 {
            trendText = "💬 Start chatting to warm up!"
        } else {
            switch trend {
            case .rising: trendText = "↑ Trending up • Keep it going!"
            case .falling: trendText = "↓ Cooling down • Chat more!"
            case .stable: trendText = "→ Steady • Nice consistency!"
            }
        }
        changeLabel.text = trendText
        changeLabel.font = .systemFont(ofSize: 12)
        changeLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        statusStack.addArrangedSubview(changeLabel)

        // Layout
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        thermometerContainer.translatesAutoresizingMaskIntoConstraints = false
        mercuryView.translatesAutoresizingMaskIntoConstraints = false
        bulbView.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            thermometerContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            thermometerContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            thermometerContainer.widthAnchor.constraint(equalToConstant: 60),
            thermometerContainer.heightAnchor.constraint(equalToConstant: 200),

            mercuryView.leadingAnchor.constraint(equalTo: thermometerContainer.leadingAnchor, constant: 8),
            mercuryView.trailingAnchor.constraint(equalTo: thermometerContainer.trailingAnchor, constant: -8),
            mercuryView.bottomAnchor.constraint(equalTo: thermometerContainer.bottomAnchor, constant: -8),
            mercuryView.heightAnchor.constraint(equalTo: thermometerContainer.heightAnchor, multiplier: temperature / 100 * 0.85),

            bulbView.topAnchor.constraint(equalTo: thermometerContainer.bottomAnchor, constant: -20),
            bulbView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bulbView.widthAnchor.constraint(equalToConstant: 80),
            bulbView.heightAnchor.constraint(equalToConstant: 80),

            emojiLabel.centerXAnchor.constraint(equalTo: bulbView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: bulbView.centerYAnchor),

            statusCard.topAnchor.constraint(equalTo: bulbView.bottomAnchor, constant: 24),
            statusCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusCard.heightAnchor.constraint(equalToConstant: 120),
            statusCard.bottomAnchor.constraint(equalTo: bottomAnchor),

            statusStack.centerXAnchor.constraint(equalTo: statusCard.centerXAnchor),
            statusStack.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor)
        ])

        // Set mercury gradient frame after layout
        DispatchQueue.main.async {
            mercuryGradient.frame = mercuryView.bounds
        }

        // Add glow animation to bulb
        addGlowAnimation(to: bulbView)
    }

    private func addGlowAnimation(to view: UIView) {
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.fromValue = 0.4
        glowAnimation.toValue = 0.8
        glowAnimation.duration = 1.5
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity

        view.layer.shadowColor = FluencaColors.primary.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 30
        view.layer.shadowOpacity = 0.6
        view.layer.add(glowAnimation, forKey: "glow")
    }
}

// MARK: - Learning Pulse View (EKG Style)
private class LearningPulseView: UIView {

    private var learningPulse: [LearningPulsePoint]
    private var dailyActivity: [DailyActivity]

    init(learningPulse: [LearningPulsePoint], dailyActivity: [DailyActivity]) {
        self.learningPulse = learningPulse
        self.dailyActivity = dailyActivity
        super.init(frame: .zero)
        setupViews()
    }

    override init(frame: CGRect) {
        self.learningPulse = []
        self.dailyActivity = []
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear

        // Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        addSubview(headerStack)

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = "Language Pulse"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleStack.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Today's conversation balance"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        titleStack.addArrangedSubview(subtitleLabel)

        headerStack.addArrangedSubview(titleStack)

        let heartLabel = UILabel()
        heartLabel.text = "💓"
        heartLabel.font = .systemFont(ofSize: 32)
        headerStack.addArrangedSubview(heartLabel)

        // Add heartbeat animation
        addHeartbeatAnimation(to: heartLabel)

        // Pulse visualization container
        let pulseContainer = UIView()
        pulseContainer.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        pulseContainer.layer.cornerRadius = 16
        addSubview(pulseContainer)

        // Legend
        let legendStack = UIStackView()
        legendStack.axis = .horizontal
        legendStack.spacing = 24
        pulseContainer.addSubview(legendStack)

        let targetLegend = createLegendItem(color: FluencaColors.secondary, text: "Target language")
        let nativeLegend = createLegendItem(color: UIColor.white.withAlphaComponent(0.3), text: "Native language")
        legendStack.addArrangedSubview(targetLegend)
        legendStack.addArrangedSubview(nativeLegend)

        // EKG bars
        let barsContainer = UIView()
        pulseContainer.addSubview(barsContainer)

        // Create bars from real data
        let barStack = UIStackView()
        barStack.axis = .horizontal
        barStack.distribution = .fillEqually
        barStack.spacing = 2
        barStack.alignment = .bottom
        barsContainer.addSubview(barStack)

        // Calculate overall target percentage from daily activity
        let totalTarget = dailyActivity.reduce(0) { $0 + $1.targetLanguageMessages }
        let totalNative = dailyActivity.reduce(0) { $0 + $1.nativeLanguageMessages }
        let totalMessages = totalTarget + totalNative
        let targetPercentage = totalMessages > 0 ? Int((Double(totalTarget) / Double(totalMessages)) * 100) : 0

        // Create bars based on learning pulse data
        let barCount = 50

        if learningPulse.isEmpty && dailyActivity.isEmpty {
            // No data - show empty state with minimal gray bars
            for _ in 0..<barCount {
                let barView = UIView()
                barView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                barView.layer.cornerRadius = 1
                barStack.addArrangedSubview(barView)

                barView.translatesAutoresizingMaskIntoConstraints = false
                barView.heightAnchor.constraint(equalToConstant: 20).isActive = true
            }
        } else {
            // Create bars from real data
            for i in 0..<barCount {
                let isTarget: Bool
                let height: CGFloat

                if !learningPulse.isEmpty {
                    // Use learning pulse data
                    let pulseIndex = i * learningPulse.count / barCount
                    let safeIndex = min(pulseIndex, learningPulse.count - 1)
                    let point = learningPulse[safeIndex]
                    isTarget = point.targetLanguagePercent >= point.nativeLanguagePercent
                    height = CGFloat(max(20, min(80, point.messageCount * 5)))
                } else {
                    // Use daily activity data
                    let activityIndex = i * dailyActivity.count / barCount
                    let safeIndex = min(activityIndex, dailyActivity.count - 1)
                    let activity = dailyActivity[safeIndex]
                    isTarget = activity.targetLanguageMessages >= activity.nativeLanguageMessages
                    let totalMessages = activity.messagesSent + activity.messagesReceived
                    height = CGFloat(max(20, min(80, totalMessages * 3)))
                }

                let barView = UIView()
                barView.backgroundColor = isTarget
                    ? FluencaColors.secondary
                    : UIColor.white.withAlphaComponent(0.2)
                barView.layer.cornerRadius = 1
                barStack.addArrangedSubview(barView)

                barView.translatesAutoresizingMaskIntoConstraints = false
                barView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        }

        // Time labels
        let timeStack = UIStackView()
        timeStack.axis = .horizontal
        timeStack.distribution = .equalSpacing
        pulseContainer.addSubview(timeStack)

        for time in ["6am", "12pm", "6pm", "Now"] {
            let label = UILabel()
            label.text = time
            label.font = .systemFont(ofSize: 10)
            label.textColor = UIColor.white.withAlphaComponent(0.4)
            timeStack.addArrangedSubview(label)
        }

        // Stats grid
        let statsGrid = UIStackView()
        statsGrid.axis = .vertical
        statsGrid.spacing = 12
        addSubview(statsGrid)

        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.spacing = 12
        row1.distribution = .fillEqually

        // Calculate today's messages from daily activity
        let todayMessages = dailyActivity.last.map { $0.messagesSent + $0.messagesReceived } ?? 0
        let yesterdayMessages = dailyActivity.dropLast().last.map { $0.messagesSent + $0.messagesReceived } ?? 0

        let targetCard = createStatCard(value: "\(targetPercentage)%", label: "Target language usage", color: FluencaColors.secondary, highlighted: true)
        let messagesCard = createStatCard(value: "\(todayMessages)", label: "Messages today", color: .white, highlighted: false)
        row1.addArrangedSubview(targetCard)
        row1.addArrangedSubview(messagesCard)
        statsGrid.addArrangedSubview(row1)

        let row2 = UIStackView()
        row2.axis = .horizontal
        row2.spacing = 12
        row2.distribution = .fillEqually

        // Calculate practice time
        let totalPracticeMinutes = dailyActivity.reduce(0) { $0 + $1.practiceMinutes }
        let practiceHours = Double(totalPracticeMinutes) / 60.0
        let practiceText = practiceHours >= 1 ? String(format: "%.1fh", practiceHours) : "\(totalPracticeMinutes)m"

        // Calculate change vs yesterday
        let change: String
        if yesterdayMessages > 0 {
            let changePercent = Int(((Double(todayMessages) - Double(yesterdayMessages)) / Double(yesterdayMessages)) * 100)
            change = changePercent >= 0 ? "↑\(changePercent)%" : "↓\(abs(changePercent))%"
        } else {
            change = todayMessages > 0 ? "↑100%" : "–"
        }

        let timeCard = createStatCard(value: practiceText, label: "Practice time", color: .white, highlighted: false)
        let changeCard = createStatCard(value: change, label: "vs. yesterday", color: FluencaColors.primary, highlighted: true)
        row2.addArrangedSubview(timeCard)
        row2.addArrangedSubview(changeCard)
        statsGrid.addArrangedSubview(row2)

        // Goal progress
        let goalContainer = UIView()
        goalContainer.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        goalContainer.layer.cornerRadius = 12
        addSubview(goalContainer)

        let goalHeader = UIStackView()
        goalHeader.axis = .horizontal
        goalHeader.distribution = .equalSpacing
        goalContainer.addSubview(goalHeader)

        let goalLabel = UILabel()
        goalLabel.text = "Daily goal: 70% target language"
        goalLabel.font = .systemFont(ofSize: 14)
        goalLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        goalHeader.addArrangedSubview(goalLabel)

        let progressLabel = UILabel()
        progressLabel.text = "\(targetPercentage)%"
        progressLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        progressLabel.textColor = FluencaColors.secondary
        goalHeader.addArrangedSubview(progressLabel)

        let progressBar = UIView()
        progressBar.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        progressBar.layer.cornerRadius = 4
        goalContainer.addSubview(progressBar)

        let progressFill = UIView()
        progressFill.backgroundColor = targetPercentage >= 70 ? FluencaColors.secondary : FluencaColors.accent
        progressFill.layer.cornerRadius = 4
        progressBar.addSubview(progressFill)

        // Layout
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        pulseContainer.translatesAutoresizingMaskIntoConstraints = false
        legendStack.translatesAutoresizingMaskIntoConstraints = false
        barsContainer.translatesAutoresizingMaskIntoConstraints = false
        barStack.translatesAutoresizingMaskIntoConstraints = false
        timeStack.translatesAutoresizingMaskIntoConstraints = false
        statsGrid.translatesAutoresizingMaskIntoConstraints = false
        goalContainer.translatesAutoresizingMaskIntoConstraints = false
        goalHeader.translatesAutoresizingMaskIntoConstraints = false
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressFill.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            pulseContainer.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 24),
            pulseContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            pulseContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            pulseContainer.heightAnchor.constraint(equalToConstant: 180),

            legendStack.topAnchor.constraint(equalTo: pulseContainer.topAnchor, constant: 16),
            legendStack.leadingAnchor.constraint(equalTo: pulseContainer.leadingAnchor, constant: 16),

            barsContainer.topAnchor.constraint(equalTo: legendStack.bottomAnchor, constant: 12),
            barsContainer.leadingAnchor.constraint(equalTo: pulseContainer.leadingAnchor, constant: 16),
            barsContainer.trailingAnchor.constraint(equalTo: pulseContainer.trailingAnchor, constant: -16),
            barsContainer.heightAnchor.constraint(equalToConstant: 100),

            barStack.leadingAnchor.constraint(equalTo: barsContainer.leadingAnchor),
            barStack.trailingAnchor.constraint(equalTo: barsContainer.trailingAnchor),
            barStack.bottomAnchor.constraint(equalTo: barsContainer.bottomAnchor),
            barStack.heightAnchor.constraint(equalToConstant: 80),

            timeStack.topAnchor.constraint(equalTo: barsContainer.bottomAnchor, constant: 8),
            timeStack.leadingAnchor.constraint(equalTo: pulseContainer.leadingAnchor, constant: 16),
            timeStack.trailingAnchor.constraint(equalTo: pulseContainer.trailingAnchor, constant: -16),

            statsGrid.topAnchor.constraint(equalTo: pulseContainer.bottomAnchor, constant: 16),
            statsGrid.leadingAnchor.constraint(equalTo: leadingAnchor),
            statsGrid.trailingAnchor.constraint(equalTo: trailingAnchor),

            goalContainer.topAnchor.constraint(equalTo: statsGrid.bottomAnchor, constant: 16),
            goalContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            goalContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            goalContainer.heightAnchor.constraint(equalToConstant: 70),
            goalContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            goalHeader.topAnchor.constraint(equalTo: goalContainer.topAnchor, constant: 16),
            goalHeader.leadingAnchor.constraint(equalTo: goalContainer.leadingAnchor, constant: 16),
            goalHeader.trailingAnchor.constraint(equalTo: goalContainer.trailingAnchor, constant: -16),

            progressBar.topAnchor.constraint(equalTo: goalHeader.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: goalContainer.leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: goalContainer.trailingAnchor, constant: -16),
            progressBar.heightAnchor.constraint(equalToConstant: 8),

            progressFill.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: min(1.0, CGFloat(targetPercentage) / 70.0))
        ])
    }

    private func createLegendItem(color: UIColor, text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 3
        stack.addArrangedSubview(dot)

        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        stack.addArrangedSubview(label)

        return stack
    }

    private func createStatCard(value: String, label: String, color: UIColor, highlighted: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = highlighted
            ? color.withAlphaComponent(0.2)
            : UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 16
        if highlighted {
            container.layer.borderWidth = 1
            container.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        container.addSubview(stack)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = highlighted ? color : .white
        stack.addArrangedSubview(valueLabel)

        let descLabel = UILabel()
        descLabel.text = label
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        stack.addArrangedSubview(descLabel)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 90)
        ])

        return container
    }

    private func addHeartbeatAnimation(to label: UILabel) {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.15, 1.0, 1.1, 1.0]
        animation.keyTimes = [0, 0.14, 0.28, 0.42, 0.7]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        label.layer.add(animation, forKey: "heartbeat")
    }
}

// MARK: - Stats Overview View
private class StatsOverviewView: UIView {

    private let wrappedStats: WrappedStats

    init(wrappedStats: WrappedStats) {
        self.wrappedStats = wrappedStats
        super.init(frame: .zero)
        setupViews()
    }

    override init(frame: CGRect) {
        self.wrappedStats = .empty
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Your Journey"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Connections across languages"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        addSubview(subtitleLabel)

        // Stats row
        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        addSubview(statsStack)

        // Format message count with commas
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let messageCountFormatted = formatter.string(from: NSNumber(value: wrappedStats.totalMessages)) ?? "\(wrappedStats.totalMessages)"

        let stats: [(icon: String, value: String, label: String)] = [
            ("💬", messageCountFormatted, "Messages"),
            ("🔥", "\(wrappedStats.longestStreak)", "Best Streak"),
            ("👥", "\(wrappedStats.totalPartners)", "Partners")
        ]

        for stat in stats {
            let card = createStatCard(icon: stat.icon, value: stat.value, label: stat.label)
            statsStack.addArrangedSubview(card)
        }

        // Wrapped preview card
        let wrappedCard = UIView()
        wrappedCard.layer.cornerRadius = 20
        wrappedCard.clipsToBounds = true
        addSubview(wrappedCard)

        // Gradient background for wrapped
        let gradient = CAGradientLayer()
        gradient.colors = [
            FluencaColors.primary.cgColor,
            FluencaColors.fireGlow.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        wrappedCard.layer.insertSublayer(gradient, at: 0)

        let wrappedStack = UIStackView()
        wrappedStack.axis = .vertical
        wrappedStack.alignment = .center
        wrappedStack.spacing = 8
        wrappedCard.addSubview(wrappedStack)

        let wrappedBadge = UIView()
        wrappedBadge.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        wrappedBadge.layer.cornerRadius = 12
        wrappedStack.addArrangedSubview(wrappedBadge)

        let badgeLabel = UILabel()
        badgeLabel.text = "Fluenca Wrapped"
        badgeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        badgeLabel.textColor = .white
        wrappedBadge.addSubview(badgeLabel)

        // Format the rolling 12-month period
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        let periodText = "\(dateFormatter.string(from: wrappedStats.periodStart)) - \(dateFormatter.string(from: wrappedStats.periodEnd))"

        let yearLabel = UILabel()
        yearLabel.text = "Last 12 Months"
        yearLabel.font = .systemFont(ofSize: 16)
        yearLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        wrappedStack.addArrangedSubview(yearLabel)

        let inLanguages = UILabel()
        inLanguages.text = "Your Language Journey"
        inLanguages.font = .systemFont(ofSize: 20, weight: .semibold)
        inLanguages.textColor = .white
        wrappedStack.addArrangedSubview(inLanguages)

        let messageCount = UILabel()
        let wrappedFormatter = NumberFormatter()
        wrappedFormatter.numberStyle = .decimal
        messageCount.text = wrappedFormatter.string(from: NSNumber(value: wrappedStats.totalMessages)) ?? "\(wrappedStats.totalMessages)"
        messageCount.font = .systemFont(ofSize: 56, weight: .bold)
        messageCount.textColor = .white
        wrappedStack.addArrangedSubview(messageCount)

        let messagesLabel = UILabel()
        messagesLabel.text = "messages exchanged"
        messagesLabel.font = .systemFont(ofSize: 16)
        messagesLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        wrappedStack.addArrangedSubview(messagesLabel)

        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share Your Wrapped ✨", for: .normal)
        shareButton.setTitleColor(FluencaColors.primary, for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        shareButton.backgroundColor = .white.withAlphaComponent(0.95)
        shareButton.layer.cornerRadius = 12
        wrappedCard.addSubview(shareButton)

        // Achievements section
        let achievementsLabel = UILabel()
        achievementsLabel.text = "Achievements"
        achievementsLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        achievementsLabel.textColor = .white
        addSubview(achievementsLabel)

        let achievementsStack = UIStackView()
        achievementsStack.axis = .horizontal
        achievementsStack.spacing = 12
        achievementsStack.distribution = .fillEqually
        addSubview(achievementsStack)

        // Use real achievements from wrapped stats, show first 4
        let displayAchievements = Array(wrappedStats.achievements.prefix(4))

        for achievement in displayAchievements {
            let emoji: String
            switch achievement.icon {
            case "flame.fill": emoji = "🔥"
            case "star.fill": emoji = "⭐"
            case "bubble.left.fill": emoji = "💬"
            case "100.circle.fill": emoji = "💯"
            case "globe": emoji = "🌍"
            case "clock.fill": emoji = "⏱️"
            case "trophy.fill": emoji = "🏆"
            case "person.3.fill": emoji = "👥"
            default: emoji = "✨"
            }
            let badge = createAchievementBadge(emoji: emoji, title: achievement.title, unlocked: achievement.isEarned)
            achievementsStack.addArrangedSubview(badge)
        }

        // Layout
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        wrappedCard.translatesAutoresizingMaskIntoConstraints = false
        wrappedStack.translatesAutoresizingMaskIntoConstraints = false
        wrappedBadge.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        achievementsLabel.translatesAutoresizingMaskIntoConstraints = false
        achievementsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            statsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            statsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            statsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            statsStack.heightAnchor.constraint(equalToConstant: 90),

            wrappedCard.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 20),
            wrappedCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrappedCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            wrappedCard.heightAnchor.constraint(equalToConstant: 300),

            wrappedStack.centerXAnchor.constraint(equalTo: wrappedCard.centerXAnchor),
            wrappedStack.topAnchor.constraint(equalTo: wrappedCard.topAnchor, constant: 24),

            wrappedBadge.heightAnchor.constraint(equalToConstant: 32),
            badgeLabel.leadingAnchor.constraint(equalTo: wrappedBadge.leadingAnchor, constant: 16),
            badgeLabel.trailingAnchor.constraint(equalTo: wrappedBadge.trailingAnchor, constant: -16),
            badgeLabel.centerYAnchor.constraint(equalTo: wrappedBadge.centerYAnchor),

            shareButton.leadingAnchor.constraint(equalTo: wrappedCard.leadingAnchor, constant: 20),
            shareButton.trailingAnchor.constraint(equalTo: wrappedCard.trailingAnchor, constant: -20),
            shareButton.bottomAnchor.constraint(equalTo: wrappedCard.bottomAnchor, constant: -20),
            shareButton.heightAnchor.constraint(equalToConstant: 48),

            achievementsLabel.topAnchor.constraint(equalTo: wrappedCard.bottomAnchor, constant: 24),
            achievementsLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            achievementsStack.topAnchor.constraint(equalTo: achievementsLabel.bottomAnchor, constant: 12),
            achievementsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            achievementsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            achievementsStack.heightAnchor.constraint(equalToConstant: 80),
            achievementsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Update gradient frame after layout
        DispatchQueue.main.async {
            gradient.frame = wrappedCard.bounds
        }
    }

    private func createStatCard(icon: String, value: String, label: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 12

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        container.addSubview(stack)

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 20)
        stack.addArrangedSubview(iconLabel)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = .white
        stack.addArrangedSubview(valueLabel)

        let descLabel = UILabel()
        descLabel.text = label
        descLabel.font = .systemFont(ofSize: 10)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        stack.addArrangedSubview(descLabel)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    private func createAchievementBadge(emoji: String, title: String, unlocked: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = unlocked
            ? FluencaColors.gold.withAlphaComponent(0.2)
            : UIColor.white.withAlphaComponent(0.05)
        container.layer.cornerRadius = 12
        container.alpha = unlocked ? 1.0 : 0.5

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        container.addSubview(stack)

        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 24)
        stack.addArrangedSubview(emojiLabel)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = unlocked ? .white : UIColor.white.withAlphaComponent(0.5)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        stack.addArrangedSubview(titleLabel)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -4)
        ])

        return container
    }
}
