//
//  ActionViewController.swift
//  ShotbotActionExtension
//
//  Created by Richard Witherspoon on 4/26/23.
//

import SwiftUI
import Persistence


final class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let attachments = item.attachments,
            let extensionContext
        else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        let viewModel = ActionExtensionViewModel(
            attachments: attachments,
            extensionContext: extensionContext,
            canSaveFramedScreenshot: PersistenceManager.shared.canSaveFramedScreenshot
        )
        
        let swiftUIView = ActionExtensionView(viewModel: viewModel)
        let childView = UIHostingController(rootView: swiftUIView)
        
        addChild(childView)
        childView.view.frame = view.bounds
        view.addSubview(childView.view)
        childView.didMove(toParent: self)
        
        childView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            childView.view.topAnchor.constraint(equalTo: view.topAnchor),
            childView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
