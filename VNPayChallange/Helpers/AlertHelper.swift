import UIKit

final class AlertHelper {
    static let shared = AlertHelper()
    private var currentAlerts: [AlertType: UIAlertController] = [:]

    private init(){}

    func showError(type: AlertType = .normal,
                    title: String? = "",
                    message: String,
                    retryHandler: (() -> Void)? = nil,
                    onCancel: (() -> Void)? = nil
    ){
        if currentAlerts[type] != nil { return }
        let alert = UIAlertController(title: title,
                                        message: message,
                                        preferredStyle: .alert)
        if let retryHandler = retryHandler {
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: {_ in
                self.dismissAlert(for: type)
                retryHandler()
            }))
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
            self.dismissAlert(for: type)
            onCancel?()
        }))

        currentAlerts[type] = alert
        if let topVC = topViewController() {
            topVC.present(alert, animated: true)
        }
    }

    func dismissAlert(for type: AlertType){
        currentAlerts[type]?.dismiss(animated: true, completion: nil)
        currentAlerts[type] = nil
    }

    var isShowingConnectionAlert: Bool {
        return currentAlerts[.connection] != nil
    }

    var isShowwingNormalAlert: Bool {
        return currentAlerts[.normal] != nil
    }

    private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}