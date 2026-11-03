import UIKit

final class HistoryHeaderView: UIView {
    var onClearHistory: (() -> Void)?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var clearButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "trash")
        configuration.baseForegroundColor = .systemRed
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.onClearHistory?()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Limpar histórico"
        button.accessibilityHint = "Remove todas as receitas do histórico"
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, clearButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HistoryHeaderView: ViewCodeProtocol {
    func buildViewHierarchy() {
        addSubview(stackView)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}
