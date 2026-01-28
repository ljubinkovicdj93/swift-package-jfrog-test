//
//  DetailViewController.swift
//  jfrog-test
//
//  Created by Djordje Ljubinkovic on 28. 1. 2026..
//

import UIKit
import SDWebImage

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: SDAnimatedImageView!

    // Assuming this is passed from the previous controller,
    // as it was referenced as self.imageURL in the Obj-C implementation.
    var imageURL: URL?

    private var tintApplied: Bool = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()

        // Right Bar Button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Toggle Animation",
            style: .plain,
            target: self,
            action: #selector(toggleAnimation(_:))
        )

        // Title View Button
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(toggleTint(_:)), for: .touchUpInside)
        button.setTitle("Tint", for: .normal)
        navigationItem.titleView = button
    }

    // MARK: - Configuration

    func configureView() {
        guard let imageView = self.imageView else { return }

        // Setup Indicator
        if imageView.sd_imageIndicator == nil {
            imageView.sd_imageIndicator = SDWebImageProgressIndicator.default
        }

        // HDR Check
        let isHDR = imageURL?.absoluteString.contains("HDR") ?? false

        if #available(iOS 17.0, *) {
            imageView.preferredImageDynamicRange = isHDR ? .high : .unspecified
        }

        // Context
        let context: [SDWebImageContextOption: Any] = [
            .imageDecodeToHDR: isHDR
        ]

        // Load Image
        imageView.sd_setImage(
            with: imageURL,
            placeholderImage: nil,
            options: [.fromLoaderOnly, .scaleDownLargeImages],
            context: context,
            progress: nil
        ) { [weak self] image, error, cacheType, imageURL in
            guard let image = image else { return }
            print("isHighDynamicRange \(image.sd_isHighDynamicRange)")
        }

        imageView.shouldCustomLoopCount = true
        imageView.animationRepeatCount = 0
    }

    // MARK: - Actions

    @objc func toggleTint(_ sender: UIResponder) {
        // Guard: Must be animating
        guard imageView.isAnimating else { return }

        // Guard: Must be SDAnimatedImage
        guard let animatedImage = imageView.image as? SDAnimatedImage else { return }

        // Guard: GIF is opaque, skip
        if animatedImage.sd_imageFormat == .GIF {
            return
        }

        // Guard: Check alpha channel
        // Note: SDImageCoderHelper is available in SDWebImage context
        guard let cgImage = animatedImage.cgImage,
              SDImageCoderHelper.cgImageContainsAlpha(cgImage) else {
            return
        }

        if tintApplied {
            imageView.animationTransformer = nil
        } else {
            imageView.animationTransformer = SDImageTintTransformer(color: .black)
        }

        tintApplied.toggle()

        // Refresh logic: Resetting the image forces the transformer to apply/remove
        if let currentImage = imageView.image {
            imageView.image = nil
            imageView.image = currentImage
        }
    }

    @objc func toggleAnimation(_ sender: UIResponder) {
        if imageView.isAnimating {
            imageView.stopAnimating()
        } else {
            imageView.startAnimating()
        }
    }
}
