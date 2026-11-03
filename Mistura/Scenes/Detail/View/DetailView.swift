import UIKit

final class DetailView: UIView {
    // MARK: - Actions

    var onRetry: (() -> Void)?
    var onVideoTap: (() -> Void)?
    var onShoppingCartTap: (([String]) -> Void)?

    // MARK: - Dependencies

    private let imageLoader: ImageLoaderType

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var ingredientsTitleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            ingredientsSectionTitle,
            videoButton
        ])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private lazy var ingredientsSectionTitle = makeSectionTitle(TextStrings.ingredientsSectionTitle)

    private lazy var ingredientsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            subtitleLabel,
            tagsLabel,
            ingredientsTitleStack,
            ingredientsStack,
            shoppingCartButton,
            makeSectionTitle(TextStrings.instructionsSectionTitle),
            instructionsLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(4, after: subtitleLabel)
        stack.setCustomSpacing(16, after: shoppingCartButton)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var subtitleLabel = makeLabel(style: .headline, color: .secondaryLabel)
    private lazy var tagsLabel = makeLabel(style: .footnote, color: .tertiaryLabel)
    private lazy var instructionsLabel = makeLabel(style: .body, color: .label)

    private lazy var shoppingCartButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = TextStrings.shoppingCartButton
        configuration.image = UIImage(systemName: "cart.fill")
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = .systemGreen
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            guard let self = self else { return }
            let uncheckedIngredients = self.getUncheckedIngredients()
            self.onShoppingCartTap?(uncheckedIngredients)
        })
        button.accessibilityLabel = "Adicionar ingredientes ao carrinho de compras"
        button.accessibilityHint = "Abre o iFood Mercado com a lista de ingredientes não marcados"
        return button
    }()

    private lazy var videoButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "play.rectangle.fill")
        configuration.baseForegroundColor = .systemRed
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.onVideoTap?()
        })
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.accessibilityLabel = "Assistir vídeo da receita no YouTube"
        button.accessibilityHint = "Abre o vídeo em um navegador externo"
        return button
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var errorLabel = makeLabel(style: .body, color: .secondaryLabel)

    private lazy var errorStack: UIStackView = {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = TextStrings.retryButton
        let retryButton = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.onRetry?()
        })
        errorLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [errorLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init

    init(imageLoader: ImageLoaderType = ImageLoader.shared) {
        self.imageLoader = imageLoader
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(with model: MealDetailModel) {
        ingredientsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        imageView.loadImage(from: model.imageURL, loader: imageLoader)
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil
        tagsLabel.text = model.tags
        tagsLabel.isHidden = model.tags == nil

        model.ingredients
            .filter { !$0.isEmpty }
            .forEach { ingredient in
                let ingredientView = IngredientItemView(ingredient: ingredient)
                ingredientsStack.addArrangedSubview(ingredientView)
            }

        instructionsLabel.text = model.instructions
        videoButton.isHidden = !model.hasVideo
    }

    private func getUncheckedIngredients() -> [String] {
        return ingredientsStack.arrangedSubviews
            .compactMap { $0 as? IngredientItemView }
            .filter { !$0.isChecked }
            .map { $0.ingredient }
    }

    // MARK: - Factories

    private func makeLabel(style: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = makeLabel(style: .title3, color: .label)
        label.font = .preferredFont(forTextStyle: .title3).withTraits(.traitBold)
        label.text = text
        return label
    }
}

// MARK: - DetailViewType
extension DetailView: DetailViewType {
    func render(_ state: DetailViewState) {
        switch state {
        case .loading:
            scrollView.isHidden = true
            errorStack.isHidden = true
            activityIndicator.startAnimating()
        case .loaded(let model):
            configure(with: model)
            scrollView.isHidden = false
            errorStack.isHidden = true
            activityIndicator.stopAnimating()
        case .error(let message):
            errorLabel.text = message
            scrollView.isHidden = true
            errorStack.isHidden = false
            activityIndicator.stopAnimating()
        }
    }
}

// MARK: - ViewCode

extension DetailView: ViewCodeProtocol {
    func buildViewHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(contentStack)
        addSubview(activityIndicator)
        addSubview(errorStack)
    }

    func setupConstraints() {
        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView.topAnchor.constraint(equalTo: content.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: frame.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: frame.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.75),

            contentStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: frame.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: frame.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            errorStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            errorStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
    }

    func setupAdditionalConfiguration() {
        backgroundColor = .systemBackground
        render(.loading)
    }
}

private extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
