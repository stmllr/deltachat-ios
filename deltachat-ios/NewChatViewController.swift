//
//  NewChatViewController.swift
//  deltachat-ios
//
//  Created by Jonas Reinsch on 21.11.17.
//  Copyright © 2017 Jonas Reinsch. All rights reserved.
//

import ALCameraViewController
import Contacts
import UIKit

protocol ChatDisplayer: class {
  func displayNewChat(contactId: Int)
  func displayChatForId(chatId: Int)
}

class NewChatViewController: UITableViewController {

	private lazy var searchController: UISearchController = {
		let searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.searchBar.placeholder = "Search Contact"
		return searchController
	}()


	var contactIds: [Int] = Utils.getContactIds() {
		didSet {
			tableView.reloadData()
		}
	}

	var contacts:[MRContact] {
		return contactIds.map({MRContact(id: $0)})
	}

	var filteredContacts: [MRContact] = []

  weak var chatDisplayer: ChatDisplayer?

  var syncObserver: Any?
  var hud: ProgressHud?

  let deviceContactHandler = DeviceContactsHandler()
  var deviceContactAccessGranted: Bool = false {
    didSet {
      tableView.reloadData()
    }
  }

  init() {
    super.init(style: .grouped)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "New Chat"
    navigationController?.navigationBar.prefersLargeTitles = true

    let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(NewChatViewController.cancelButtonPressed))
    navigationItem.rightBarButtonItem = cancelButton

    deviceContactHandler.importDeviceContacts(delegate: self)
		navigationItem.searchController = searchController
		definesPresentationContext = true // to make sure searchbar will only be shown in this viewController
  }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.deviceContactAccessGranted = CNContactStore.authorizationStatus(for: .contacts) == .authorized
		contactIds = Utils.getContactIds()

		// this will show the searchbar on launch -> will be set back to true on viewDidAppear
		if #available(iOS 11.0, *) {
			navigationItem.hidesSearchBarWhenScrolling = false
		}

	}

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
		if #available(iOS 11.0, *) {
			navigationItem.hidesSearchBarWhenScrolling = true
		}

    let nc = NotificationCenter.default
    syncObserver = nc.addObserver(
      forName: dcNotificationSecureJoinerProgress,
      object: nil,
      queue: nil
    ) {
      notification in
      if let ui = notification.userInfo {
        if ui["error"] as! Bool {
          self.hud?.error(ui["errorMessage"] as? String)
        } else if ui["done"] as! Bool {
          self.hud?.done()
        } else {
          self.hud?.progress(ui["progress"] as! Int)
        }
      }
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)

    let nc = NotificationCenter.default
    if let syncObserver = self.syncObserver {
      nc.removeObserver(syncObserver)
    }
  }

  @objc func cancelButtonPressed() {
    dismiss(animated: true, completion: nil)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - Table view data source

  override func numberOfSections(in _: UITableView) -> Int {
		return deviceContactAccessGranted ? 2 : 3
  }



  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return 3
		} else if section == 1 {
			if deviceContactAccessGranted {
				return contactIds.count
			} else {
				return 1
			}
		} else {
				return contactIds.count
		}
  }



  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let section = indexPath.section
    let row = indexPath.row

		if section == 0 {
			if row == 0 {
				// new group row
				let cell: UITableViewCell
				if let c = tableView.dequeueReusableCell(withIdentifier: "newContactCell") {
					cell = c
				} else {
					cell = UITableViewCell(style: .default, reuseIdentifier: "newContactCell")
				}
				cell.textLabel?.text = "New Group"
				cell.textLabel?.textColor = view.tintColor

				return cell
			}
			if row == 1 {
				// new contact row
				let cell: UITableViewCell
				if let c = tableView.dequeueReusableCell(withIdentifier: "scanGroupCell") {
					cell = c
				} else {
					cell = UITableViewCell(style: .default, reuseIdentifier: "scanGroupCell")
				}
				cell.textLabel?.text = "Scan Group QR Code"
				cell.textLabel?.textColor = view.tintColor

				return cell
			}

			if row == 2 {
				// new contact row
				let cell: UITableViewCell
				if let c = tableView.dequeueReusableCell(withIdentifier: "newContactCell") {
					cell = c
				} else {
					cell = UITableViewCell(style: .default, reuseIdentifier: "newContactCell")
				}
				cell.textLabel?.text = "New Contact"
				cell.textLabel?.textColor = view.tintColor

				return cell
			}
		} else if section == 1 {
			if deviceContactAccessGranted {
				let cell: ContactCell
				if let c = tableView.dequeueReusableCell(withIdentifier: "contactCell") as? ContactCell {
					cell = c
				} else {
					cell = ContactCell(style: .default, reuseIdentifier: "contactCell")
				}
				let contactId = contactIds[row]
				updateContactCell(cell: cell, contactId: contactId)
				return cell
			} else {
				let cell: ActionCell
				if let c = tableView.dequeueReusableCell(withIdentifier: "actionCell") as? ActionCell {
					cell = c
				} else {
					cell = ActionCell(style: .default, reuseIdentifier: "actionCell")
				}
				cell.actionTitle = "Import Device Contacts"
				return cell
			}
		} else {
			// section 2
			let cell: ContactCell
			if let c = tableView.dequeueReusableCell(withIdentifier: "contactCell") as? ContactCell {
				cell = c
			} else {
				cell = ContactCell(style: .default, reuseIdentifier: "contactCell")
			}
			let contactId = contactIds[row]
			updateContactCell(cell: cell, contactId: contactId)
			return cell
		}
		// will actually never get here but compiler not happy
		return UITableViewCell(style: .default, reuseIdentifier: "cell")
  }


  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = indexPath.row
		let section = indexPath.section

		if section == 0 {
			if row == 0 {
				let newGroupController = NewGroupViewController()
				navigationController?.pushViewController(newGroupController, animated: true)
			}
			if row == 1 {
				if UIImagePickerController.isSourceTypeAvailable(.camera) {
					let controller = QrCodeReaderController()
					controller.delegate = self
					present(controller, animated: true, completion: nil)

				} else {
					let alert = UIAlertController(title: "Camera is not available", message: nil, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
						self.dismiss(animated: true, completion: nil)
					}))
					present(alert, animated: true, completion: nil)
				}
			}
			if row == 2 {
				let newContactController = NewContactController()
				navigationController?.pushViewController(newContactController, animated: true)
			}
		} else if section == 1 {
			if deviceContactAccessGranted {
				let contactIndex = row
				let contactId = contactIds[contactIndex]
				dismiss(animated: false) {
					self.chatDisplayer?.displayNewChat(contactId: contactId)
				}
			} else {
				showSettingsAlert()
			}
		} else {
			let contactIndex = row
			let contactId = contactIds[contactIndex]
			dismiss(animated: false) {
				self.chatDisplayer?.displayNewChat(contactId: contactId)
			}
		}
  }


  override func tableView(_: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    let row = indexPath.row
    if row > 2 {
      let contactIndex = row - 3
      let contactId = contactIds[contactIndex]
      // let newContactController = NewContactController(contactIdForUpdate: contactId)
      // navigationController?.pushViewController(newContactController, animated: true)
      let contactProfileController = ContactProfileViewController(contactId: contactId)
      navigationController?.pushViewController(contactProfileController, animated: true)
    }
  }

	private func updateContactCell(cell: ContactCell, contactId: Int) {
		let contact = MRContact(id: contactId)
		cell.nameLabel.text = contact.name
		cell.emailLabel.text = contact.email
		cell.initialsLabel.text = Utils.getInitials(inputName: contact.name)
		cell.setColor(contact.color)
		cell.accessoryType = .detailDisclosureButton
	}

	private func searchBarIsEmpty() -> Bool {
		return searchController.searchBar.text?.isEmpty ?? true
	}

	private func filterContentForSearchText(_ searchText: String, scope: String = "All") {

		filteredContacts = contacts.filter({ (contact: MRContact) -> Bool in
			let matches = contact.name.lowercased().contains(searchText.lowercased()) || contact.email.lowercased().contains(searchText.lowercased())
			return matches
		})
		tableView.reloadData()


	}

}

extension NewChatViewController: QrCodeReaderDelegate {
  func handleQrCode(_ code: String) {
    logger.info("decoded: \(code)")

    let check = dc_check_qr(mailboxPointer, code)!
    logger.info("got ver: \(check)")

    if dc_lot_get_state(check) == DC_QR_ASK_VERIFYGROUP {
      hud = ProgressHud("Synchronizing Account", in: view)
      DispatchQueue.global(qos: .userInitiated).async {
        let id = dc_join_securejoin(mailboxPointer, code)

        DispatchQueue.main.async {
          self.dismiss(animated: true) {
            self.chatDisplayer?.displayChatForId(chatId: Int(id))
          }
        }
      }
    } else {
      let alert = UIAlertController(title: "Not a valid group QR Code", message: code, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
        self.dismiss(animated: true, completion: nil)
      }))
      present(alert, animated: true, completion: nil)
    }
    dc_lot_unref(check)
  }
}

extension NewChatViewController: DeviceContactsDelegate {
  func accessGranted() {
    deviceContactAccessGranted = true
  }

  func accessDenied() {
    deviceContactAccessGranted = false
  }

  private func showSettingsAlert() {
    let alert = UIAlertController(
			title: "Import Contacts from to your device",
			message: "To chat with contacts from your device open the settings menu and enable the Contacts option",
			preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
      UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
    })
    present(alert, animated: true)
  }
}

extension NewChatViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		// TODO
	}
}

protocol DeviceContactsDelegate {
  func accessGranted()
  func accessDenied()
}
