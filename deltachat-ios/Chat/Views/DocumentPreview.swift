import UIKit
import DcCore

public class DocumentPreview: DraftPreview {

    weak var delegate: DraftPreviewDelegate?

    lazy var fileView: FileView = {
        let view = FileView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowLayoutChange = false
        return view
    }()

    override func setupSubviews() {
        super.setupSubviews()
        mainContentView.addSubview(fileView)
        addConstraints([
            fileView.constraintAlignTopTo(mainContentView),
            fileView.constraintAlignLeadingTo(mainContentView, paddingLeading: 8),
            fileView.constraintAlignBottomTo(mainContentView),
            fileView.constraintAlignTrailingTo(mainContentView)
        ])
        fileView.fillSuperview()
        mainContentView.constraintHeightTo(75).isActive = true
    }
    
    override public func cancel() {
        fileView.prepareForReuse()
        delegate?.onCancelAttachment()
    }

    override public func configure(draft: DraftModel) {
        if draft.draftViewType == DC_MSG_FILE, let path = draft.draftAttachment {
            let tmpMsg = DcMsg(viewType: DC_MSG_FILE)
            tmpMsg.setFile(filepath: path)
            tmpMsg.text = draft.draftText
            fileView.configure(message: tmpMsg)
            self.delegate?.onAttachmentAdded()
            isHidden = false
        } else {
            isHidden = true
        }
    }
}