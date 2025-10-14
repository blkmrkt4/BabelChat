import UIKit

/// Container for AI Model Setup pages with swipe navigation
class AISetupContainerViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()

    // View controllers
    private let setupVC = AISetupViewController()
    private let bindingsVC = AIModelBindingsViewController()

    private var currentPage = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "AI Configuration"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        setupScrollView()
        setupPageControl()
        addChildViewControllers()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
    }

    private func setupPageControl() {
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = 2
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)
        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func addChildViewControllers() {
        // Add AI Setup ViewController (Page 1)
        addChild(setupVC)
        scrollView.addSubview(setupVC.view)
        setupVC.view.translatesAutoresizingMaskIntoConstraints = false
        setupVC.didMove(toParent: self)

        // Add AI Model Bindings ViewController (Page 2)
        addChild(bindingsVC)
        scrollView.addSubview(bindingsVC.view)
        bindingsVC.view.translatesAutoresizingMaskIntoConstraints = false
        bindingsVC.didMove(toParent: self)

        NSLayoutConstraint.activate([
            // Page 1 - AI Setup
            setupVC.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            setupVC.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            setupVC.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            setupVC.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Page 2 - AI Model Bindings
            bindingsVC.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            bindingsVC.view.leadingAnchor.constraint(equalTo: setupVC.view.trailingAnchor),
            bindingsVC.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            bindingsVC.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Content size
            bindingsVC.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            bindingsVC.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func pageControlChanged() {
        let page = pageControl.currentPage
        let offset = CGPoint(x: CGFloat(page) * view.bounds.width, y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }

    // MARK: - Title Updates

    private func updateTitle(for page: Int) {
        switch page {
        case 0:
            title = "AI Model Setup"
        case 1:
            title = "AI Model Bindings"
        default:
            title = "AI Configuration"
        }
    }
}

// MARK: - UIScrollViewDelegate

extension AISetupContainerViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / view.bounds.width))
        if pageIndex != currentPage {
            currentPage = pageIndex
            pageControl.currentPage = currentPage
            updateTitle(for: currentPage)
        }
    }
}
