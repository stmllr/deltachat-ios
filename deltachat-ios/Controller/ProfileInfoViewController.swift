import UIKit
import DcCore

class ProfileInfoViewController: UITableViewController {

    var displayName: String?

    private lazy var doneButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(
            title: String.localized("done"),
            style: .done,
            target: self,
            action: #selector(doneButtonPressed(_:))
        )
    }()

    private lazy var headerCell: TextCell = {
        let cell = TextCell(style: .default, reuseIdentifier: nil)
        let email = dcContext.addr ?? ""
        cell.content = String.localizedStringWithFormat(NSLocalizedString("qraccount_success_enter_name", comment: ""), email)
        return cell
    }()

    private lazy var emailCell: TextFieldCell = {
        let cell = TextFieldCell(description: "Meine Email Adresse", placeholder: "Meine Email")
        cell.setText(text: dcContext.addr)
        return cell
    }()

    private lazy var avatarCell: UITableViewCell = {
        let cell = AvatarSelectionCell(context: self.dcContext)
        cell.onAvatarTapped = avatarTapped
        return cell
    }()

    private lazy var nameCell: TextFieldCell = {
        let cell =  TextFieldCell.makeNameCell()
        cell.placeholder = String.localized("pref_your_name")
        cell.setText(text: dcContext.displayname)
        cell.onTextFieldChange = {[unowned self] textField in
            self.displayName = textField.text
        }
        return cell
    }()

    private lazy var cells = [headerCell, avatarCell, nameCell]

    private let dcContext: DcContext

    init(context: DcContext) {
        self.dcContext = context
        super.init(style: .grouped)
        tableView.estimatedRowHeight = Constants.defaultCellHeight
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String.localized("pref_profile_info_headline")
        navigationItem.rightBarButtonItem = doneButtonItem
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let cell = cells[indexPath.row]

        if let textCell = cell as? TextCell {
            return textCell.intrinsicCellHeight
        }

        if cell is AvatarSelectionCell {
            return AvatarSelectionCell.cellHeight
        }

        return Constants.defaultCellHeight
    }

    private func avatarTapped() {

    }

    @objc private func doneButtonPressed(_ sender: UIBarButtonItem) {
        dcContext.displayname = displayName
        self.dismiss(animated: true, completion: nil)
    }

}
