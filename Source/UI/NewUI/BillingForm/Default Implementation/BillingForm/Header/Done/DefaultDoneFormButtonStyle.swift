import UIKit

public struct DefaultDoneFormButtonStyle: ElementButtonStyle {
    public var image: UIImage?
    public var text: String = Constants.LocalizationKeys.BillingForm.Header.done
    public var font: UIFont = UIFont(graphikStyle: .regular, size: Constants.Style.BillingForm.DoneButton.fontSize.rawValue)
    public var disabledTextColor: UIColor = .doveGray
    public var disabledTintColor: UIColor = .doveGray
    public var activeTintColor: UIColor = .brandeisBlue
    public var backgroundColor: UIColor = .clear
    public var normalBorderColor: UIColor = .clear
    public var focusBorderColor: UIColor = .clear
    public var errorBorderColor: UIColor = .clear
    public var imageTintColor: UIColor = .clear
    public var textColor: UIColor = .brandeisBlue
    public var isHidden: Bool = false
    public var isEnabled: Bool = true
    public var height: Double = Constants.Style.BillingForm.DoneButton.height.rawValue
    public var width: Double = Constants.Style.BillingForm.DoneButton.width.rawValue
    public var cornerRadius: CGFloat = 0
    public var borderWidth: CGFloat = 0
    public var textLeading: CGFloat = 0
}
