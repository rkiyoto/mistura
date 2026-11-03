import UIKit

final class IngredientItemView: UIView {
    private(set) var isChecked = false
    let ingredient: String

    private lazy var checkboxButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "circle")
        configuration.baseForegroundColor = .systemGray
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.toggleCheckbox()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private lazy var ingredientLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [checkboxButton, ingredientLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(ingredient: String) {
        self.ingredient = ingredient
        super.init(frame: .zero)
        ingredientLabel.text = ingredient
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func toggleCheckbox() {
        isChecked.toggle()
        updateCheckboxAppearance()
    }

    private func updateCheckboxAppearance() {
        let imageName = isChecked ? "checkmark.circle.fill" : "circle"
        let color: UIColor = isChecked ? .systemGreen : .systemGray

        checkboxButton.configuration?.image = UIImage(systemName: imageName)
        checkboxButton.configuration?.baseForegroundColor = color

        // Aplica strikethrough no texto quando marcado
        if isChecked {
            let attributedString = NSAttributedString(
                string: ingredient,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
            ingredientLabel.attributedText = attributedString
        } else {
            ingredientLabel.attributedText = nil
            ingredientLabel.text = ingredient
            ingredientLabel.textColor = .label
        }
    }
}
