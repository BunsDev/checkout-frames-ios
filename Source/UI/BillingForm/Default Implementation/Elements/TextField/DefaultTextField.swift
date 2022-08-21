import UIKit

public struct DefaultTextField: ElementTextFieldStyle {
    public var textAlignment: NSTextAlignment = .natural
    public var isHidden = false
    public var isSupportingNumericKeyboard = false
    public var text: String = ""
    public var placeholder: String?
    public var textColor: UIColor = .codGray
    public var normalBorderColor: UIColor = .mediumGray
    public var focusBorderColor: UIColor = .brandeisBlue
    public var errorBorderColor: UIColor = .tallPoppyRed
    public var backgroundColor: UIColor = .clear
    public var tintColor: UIColor = .codGray
    public var borderWidth: CGFloat = 1.0
    public var cornerRadius: CGFloat = 10.0
    public var width: Double = Constants.Style.BillingForm.InputTextField.width.rawValue
    public var height: Double = Constants.Style.BillingForm.InputTextField.height.rawValue
    public var font = UIFont.systemFont(ofSize: Constants.Style.BillingForm.InputTextField.fontSize.rawValue)
}
