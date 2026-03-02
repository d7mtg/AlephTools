import UIKit
import KeyboardKit

class KeyboardViewController: KeyboardInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardKit(for: .alephKeyboard)
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { controller in
            PaleoKeyboardView(
                services: controller.services
            )
        }
    }
}
