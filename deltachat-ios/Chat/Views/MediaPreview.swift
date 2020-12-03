import UIKit
import SDWebImage
import DcCore

class MediaPreview: DraftPreview {
    var imageWidthConstraint: NSLayoutConstraint?
    weak var delegate: DraftPreviewDelegate?

    lazy var contentImageView: SDAnimatedImageView = {
        let imageView = SDAnimatedImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    override func setupSubviews() {
        super.setupSubviews()
        mainContentView.addSubview(contentImageView)
        addConstraints([
            contentImageView.constraintAlignTopTo(mainContentView),
            contentImageView.constraintAlignLeadingMaxTo(mainContentView, paddingLeading: 12),
            contentImageView.constraintAlignTrailingTo(mainContentView, paddingTrailing: 14),
            contentImageView.constraintAlignBottomTo(mainContentView),
            contentImageView.constraintHeightTo(90)
        ])
    }

    override func configure(draft: DraftModel) {
        if (draft.draftViewType == DC_MSG_GIF || draft.draftViewType == DC_MSG_IMAGE), let path = draft.draftAttachment {
            contentImageView.sd_setImage(with: URL(fileURLWithPath: path, isDirectory: false), completed: { image, error, _, _ in
                if let error = error {
                    logger.error("could not load draft image: \(error)")
                    self.cancel()
                } else if let image = image {
                    self.setAspectRatio(image: image)
                    self.delegate?.onAttachmentAdded()
                }
            })
            isHidden = false
        } else {
            isHidden = true
        }
    }

    override public func cancel() {
        contentImageView.sd_cancelCurrentImageLoad()
        contentImageView.image = nil
        delegate?.onCancelAttachment()
    }

    func setAspectRatio(image: UIImage) {
        let height = image.size.height
        let width = image.size.width
        imageWidthConstraint?.isActive = false
        imageWidthConstraint = contentImageView.widthAnchor.constraint(lessThanOrEqualTo: contentImageView.heightAnchor, multiplier: width / height)
        imageWidthConstraint?.isActive = true
    }
}