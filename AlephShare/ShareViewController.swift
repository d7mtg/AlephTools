import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        extractText { [weak self] text in
            DispatchQueue.main.async {
                guard let self else { return }
                let shareView = ShareView(
                    inputText: text,
                    onDone: {
                        self.extensionContext?.completeRequest(returningItems: nil)
                    }
                )
                let host = UIHostingController(rootView: shareView)
                self.addChild(host)
                self.view.addSubview(host.view)
                host.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    host.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                    host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                ])
                host.didMove(toParent: self)
            }
        }
    }

    private func extractText(completion: @escaping (String) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            completion("")
            return
        }

        let textType = UTType.plainText.identifier
        if provider.hasItemConformingToTypeIdentifier(textType) {
            provider.loadItem(forTypeIdentifier: textType) { data, _ in
                let text = data as? String ?? ""
                completion(text)
            }
        } else {
            completion("")
        }
    }
}
