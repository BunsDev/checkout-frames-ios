import UIKit

public struct DefaultBillingSummaryViewStyle: BillingSummaryViewStyle {
    public var isMandatory = true
    public var separatorLineColor: UIColor = FramesUIStyle.Color.borderSecondary
    public var backgroundColor: UIColor = .clear
    public var button: ElementButtonStyle = DefaultEditBillingDetailsButtonStyle()
    public var title: ElementStyle? = DefaultTitleLabelStyle(text: Constants.LocalizationKeys.PaymentForm.BillingSummary.title)
    public var hint: ElementStyle? = DefaultHintInputLabelStyle(text: Constants.LocalizationKeys.PaymentForm.BillingSummary.hint)
    public var summary: ElementStyle? = DefaultTitleLabelStyle()
    public var mandatory: ElementStyle?
    public var error: ElementErrorViewStyle?

    public lazy var borderStyle: ElementBorderStyle = {
        DefaultBorderStyle(cornerRadius: Constants.Style.BorderStyle.cornerRadius,
                           borderWidth: 0.5,
                           normalColor: FramesUIStyle.Color.borderPrimary,
                           focusColor: .clear,
                           errorColor: .clear)
    }()
}
