import UIKit

struct MealCellModel: Equatable {
    let id: String
    let title: String
    let imageURL: URL?
}

extension MealCellModel {
    init(meal: MealSummary) {
        self.init(id: meal.id,
                  title: meal.name,
                  imageURL: meal.thumbnailURL)
    }
}

final class MealCell: UITableViewCell {
    static let reuseIdentifier = "MealCell"

    private var imageTask: Task<Void, Never>?

    // MARK: - UI Components

    private lazy var thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .secondarySystemFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        thumbnailImageView.image = nil
    }

    func configure(with model: MealCellModel, imageLoader: ImageLoaderType = ImageLoader.shared) {
        titleLabel.text = model.title
        imageTask?.cancel()
        imageTask = thumbnailImageView.loadImage(from: model.imageURL, loader: imageLoader)
    }
}

// MARK: - ViewCode

extension MealCell: ViewCodeProtocol {
    func buildViewHierarchy() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 56),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8)
        ])
    }

    func setupAdditionalConfiguration() {
        accessoryType = .disclosureIndicator
    }
}
