import UIKit

public protocol BillingSummaryViewStyle: CellButtonStyle {
    var summary: ElementStyle? { get set }
    var borderStyle: ElementBorderStyle { get set }
    var separatorLineColor: UIColor { get set }

    @available(*, deprecated, renamed: "borderStyle.cornerRadius")
    var cornerRadius: CGFloat { get set }

    @available(*, deprecated, renamed: "borderStyle.borderWidth")
    var borderWidth: CGFloat { get set }

    @available(*, deprecated, renamed: "borderStyle.normalColor")
    var borderColor: UIColor { get set }
}

public extension BillingSummaryViewStyle {

    @available(*, deprecated, renamed: "borderStyle.cornerRadius")
    var cornerRadius: CGFloat {
        get {
            Constants.Style.BorderStyle.cornerRadius
        }
        set {
            borderStyle.cornerRadius = newValue
        }
    }

    var borderWidth: CGFloat {
        get {
            Constants.Style.BorderStyle.borderWidth
        }
        set {
            borderStyle.borderWidth = newValue
        }
    }

    var borderColor: UIColor {
        get {
            FramesUIStyle.Color.borderPrimary
        }
        set {
            borderStyle.normalColor = newValue
        }
    }

    var borderStyle: ElementBorderStyle {
        // Deprecated warning required to encourage migrating away from using these properties
        get {
            DefaultBorderStyle(cornerRadius: cornerRadius,
                               borderWidth: borderWidth,
                               normalColor: borderColor,
                               focusColor: .clear,
                               errorColor: .clear,
                               edges: .all,
                               corners: .allCorners)
        }
        set(newValue) {
            borderStyle = newValue
        }
    }
}
