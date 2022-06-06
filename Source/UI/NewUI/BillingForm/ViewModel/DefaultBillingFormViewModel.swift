import UIKit
import Checkout

final class DefaultBillingFormViewModel: BillingFormViewModel {
    var style: BillingFormStyle
    var updateRow: (() -> Void)?
    var updatedRow: Int? {
        didSet {
            updateRow?()
        }
    }

    var errorFlagOfCellType = [Int: Bool]()
    var textValueOfCellType = [Int: String]()

    weak var editDelegate: BillingFormViewModelEditingDelegate?
    weak var delegate: BillingFormViewModelDelegate?

    private var initialCountry: String
    private var initialRegionCode: String?
    private var countryCode: Int = 0

    init(style: BillingFormStyle,
         initialCountry: String = "",
         initialRegionCode: String? = nil,
         delegate: BillingFormViewModelDelegate? = nil) {
        self.style = style
        self.initialCountry = initialCountry
        self.initialRegionCode = initialRegionCode
        self.delegate = delegate
    }

    func getHeaderView(delegate: BillingFormHeaderCellDelegate?) -> UIView {
        var style = style.header
        style.doneButton.isEnabled = textValueOfCellType.values.count == self.style.cells.count
        let view = BillingFormHeaderCell(style: style, delegate: delegate)
        self.editDelegate = view
        return view
    }

    func getCell( row: Int, delegate: BillingFormTextFieldCellDelegate?) -> UITableViewCell {
        let currentStyle = style.cells[row]
        guard style.cells.count > row,
              var cellStyle = currentStyle.style
        else { return UITableViewCell() }

        if cellStyle.isOptional {
            textValueOfCellType[currentStyle.index, default: ""] += ""
            errorFlagOfCellType[currentStyle.index] = false
        }

        let hash = currentStyle.index
        updateErrorView(with: &cellStyle, hashValue: hash)
        updateTextField(with: &cellStyle, hashValue: hash)

        let cell = CKOTextFieldCell()
        cell.delegate = delegate
        cell.update(cellStyle: currentStyle, style: cellStyle, tag: row)
        return cell
    }

    private func updateErrorView(with style: inout CKOTextFieldCellStyle, hashValue: Int) {
        guard let hasError = errorFlagOfCellType[hashValue] else { return }
        style.error.isHidden = !hasError
    }

    private func updateTextField(with style: inout CKOTextFieldCellStyle, hashValue: Int) {
        guard let text = textValueOfCellType[hashValue] else { return }
        style.textfield.text = text
    }
}

extension DefaultBillingFormViewModel: BillingFormViewControllerdelegate {

    func updateCountryCode(code: Int) {
        countryCode = code
    }

    func getViewForHeader(sender: UIViewController) -> UIView? {
        return getHeaderView(delegate: sender as? BillingFormHeaderCellDelegate)
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func textFieldShouldEndEditing(textField: BillingFormTextField, replacementString: String) {
        validate(text: textField.text, cellStyle: textField.type, row: textField.tag)

        if !(textField.text?.isEmpty ?? true) || textField.type.style?.isOptional ?? false {
            textValueOfCellType[textField.type.index] = textField.text
        } else {
            textValueOfCellType[textField.type.index] = nil

        }
        updatedRow = textField.tag
    }

    func textFieldShouldChangeCharactersIn(textField: UITextField, replacementString string: String) {
        guard let textField = textField as? BillingFormTextField else { return }
        validate(text: string, cellStyle: textField.type, row: textField.tag)

        if !(string.isEmpty) {
            textValueOfCellType[textField.type.index] = string
        } else if textField.text?.count ?? 1 == 1, !(textField.type.style?.isOptional ?? false) {
            textValueOfCellType[textField.type.index] = nil
        }

        let isSuccessful =  textValueOfCellType.values.count == style.cells.count && !(errorFlagOfCellType.isEmpty || errorFlagOfCellType.values.allSatisfy({$0}))
        editDelegate?.didFinishEditingBillingForm(successfully: isSuccessful)
    }

    func tableView(estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(numberOfRowsInSection section: Int) -> Int {
        style.cells.count
    }

    func tableView(tableView: UITableView, cellForRowAt indexPath: IndexPath, sender: UIViewController) -> UITableViewCell {
        getCell(row: indexPath.row, delegate: sender as? BillingFormViewController)
    }

    func doneButtonIsPressed(sender: UIViewController) {

        let phone = Phone(
            number: textValueOfCellType[BillingFormCell.phoneNumber(nil).index],
            country: nil)

        let address = Address(
            addressLine1: textValueOfCellType[BillingFormCell.addressLine1(nil).index],
            addressLine2: textValueOfCellType[BillingFormCell.addressLine2(nil).index],
            city: textValueOfCellType[BillingFormCell.city(nil).index],
            state: textValueOfCellType[BillingFormCell.state(nil).index],
            zip: textValueOfCellType[BillingFormCell.postcode(nil).index],
            country: nil)

        delegate?.onTapDoneButton(address: address, phone: phone)
        sender.dismiss(animated: true)
    }

    func cancelButtonIsPressed(sender: UIViewController) {
        sender.dismiss(animated: true)
    }

    internal func validate(text: String?, cellStyle: BillingFormCell, row: Int) {
        guard cellStyle.index <= errorFlagOfCellType.count,
              cellStyle.index >= 0,
                let style = cellStyle.style,
                !style.isOptional else {
            errorFlagOfCellType[cellStyle.index] = false
            return
        }
        errorFlagOfCellType[cellStyle.index] = cellStyle.validator.validate(text: text)
    }
}
