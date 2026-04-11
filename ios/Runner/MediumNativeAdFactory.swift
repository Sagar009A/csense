import Flutter
import google_mobile_ads
import GoogleMobileAds
import UIKit

class MediumNativeAdFactory: NSObject, FLTNativeAdFactory {

    func createNativeAd(_ nativeAd: NativeAd,
                        customOptions: [AnyHashable: Any]? = nil) -> NativeAdView? {

        // ── Extract custom options ──────────────────────────
        let isDarkMode = customOptions?["isDarkMode"] as? Bool ?? false
        let cornerRadius: CGFloat = (customOptions?["cornerRadius"] as? NSNumber)?.doubleValue ?? 12
        let buttonColorInt = customOptions?["buttonColor"] as? Int
        let buttonTextColorInt = customOptions?["buttonTextColor"] as? Int

        let buttonColor = buttonColorInt.map { uiColorFromArgb($0) }
            ?? UIColor(red: 0.54, green: 0.36, blue: 0.96, alpha: 1)
        let buttonTextColor = buttonTextColorInt.map { uiColorFromArgb($0) } ?? .white

        let bgColor: UIColor = isDarkMode
            ? UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
            : .white
        let headlineColor: UIColor = isDarkMode
            ? .white
            : UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1)
        let bodyColor: UIColor = isDarkMode
            ? UIColor(red: 0.58, green: 0.64, blue: 0.72, alpha: 1)
            : UIColor(red: 0.39, green: 0.45, blue: 0.55, alpha: 1)

        // ── Container ───────────────────────────────────────
        let adView = NativeAdView()
        adView.backgroundColor = bgColor
        adView.layer.cornerRadius = cornerRadius
        adView.clipsToBounds = true

        // ── Icon ────────────────────────────────────────────
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        iconView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(iconView)
        adView.iconView = iconView

        // ── Headline ────────────────────────────────────────
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headlineLabel.textColor = headlineColor
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(headlineLabel)
        adView.headlineView = headlineLabel

        // ── Body ────────────────────────────────────────────
        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = bodyColor
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(bodyLabel)
        adView.bodyView = bodyLabel

        // ── Advertiser ──────────────────────────────────────
        let advertiserLabel = UILabel()
        advertiserLabel.font = .systemFont(ofSize: 12)
        advertiserLabel.textColor = bodyColor
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(advertiserLabel)
        adView.advertiserView = advertiserLabel

        // ── Media ───────────────────────────────────────────
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 8
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(mediaView)
        adView.mediaView = mediaView

        // ── CTA Button ──────────────────────────────────────
        let ctaButton = UIButton(type: .custom)
        ctaButton.backgroundColor = buttonColor
        ctaButton.setTitleColor(buttonTextColor, for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        ctaButton.layer.cornerRadius = cornerRadius
        ctaButton.isUserInteractionEnabled = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        adView.addSubview(ctaButton)
        adView.callToActionView = ctaButton

        // ── "Ad" badge ──────────────────────────────────────
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = .systemFont(ofSize: 10, weight: .bold)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1)
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(adBadge)

        // ── Layout ──────────────────────────────────────────
        let pad: CGFloat = 12
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            iconView.topAnchor.constraint(equalTo: adView.topAnchor, constant: pad),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            headlineLabel.topAnchor.constraint(equalTo: adView.topAnchor, constant: pad),

            advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            advertiserLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2),

            mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            mediaView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            mediaView.heightAnchor.constraint(equalToConstant: 160),

            bodyLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            bodyLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            bodyLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),

            ctaButton.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: pad),
            ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            ctaButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            ctaButton.heightAnchor.constraint(equalToConstant: 40),
            ctaButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -pad),

            adBadge.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -pad),
            adBadge.topAnchor.constraint(equalTo: adView.topAnchor, constant: pad),
            adBadge.widthAnchor.constraint(equalToConstant: 24),
            adBadge.heightAnchor.constraint(equalToConstant: 16),
        ])

        // ── Populate ────────────────────────────────────────
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil
        advertiserLabel.text = nativeAd.advertiser
        advertiserLabel.isHidden = nativeAd.advertiser == nil
        iconView.image = nativeAd.icon?.image
        iconView.isHidden = nativeAd.icon == nil
        mediaView.isHidden = nativeAd.mediaContent.mainImage == nil
            && !nativeAd.mediaContent.hasVideoContent
        ctaButton.setTitle(nativeAd.callToAction, for: .normal)
        ctaButton.isHidden = nativeAd.callToAction == nil
        adView.nativeAd = nativeAd

        return adView
    }

    private func uiColorFromArgb(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
