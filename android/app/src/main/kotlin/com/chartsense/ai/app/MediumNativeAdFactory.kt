package com.chartsense.ai.app

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MediumNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val layoutInflater = LayoutInflater.from(context)
        val adView = layoutInflater.inflate(R.layout.native_ad_medium, null) as NativeAdView

        // Get custom options with defaults
        val buttonColor = customOptions?.get("buttonColor") as? Int ?: 0xFF8B5CF6.toInt()
        val buttonTextColor = customOptions?.get("buttonTextColor") as? Int ?: 0xFFFFFFFF.toInt()
        val backgroundColor = customOptions?.get("backgroundColor") as? Int ?: 0xFFFFFFFF.toInt()
        val cornerRadius = (customOptions?.get("cornerRadius") as? Double)?.toFloat() ?: 12f
        val isDarkMode = customOptions?.get("isDarkMode") as? Boolean ?: false

        // Set background color
        val container = adView.findViewById<LinearLayout>(R.id.ad_container)
        val containerBackground = GradientDrawable().apply {
            setColor(if (isDarkMode) 0xFF1A1A24.toInt() else backgroundColor)
            this.cornerRadius = cornerRadius * context.resources.displayMetrics.density
        }
        container.background = containerBackground

        // Headline
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        headlineView.setTextColor(if (isDarkMode) Color.WHITE else Color.parseColor("#1E293B"))
        adView.headlineView = headlineView

        // Body
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
            bodyView.setTextColor(if (isDarkMode) Color.parseColor("#94A3B8") else Color.parseColor("#64748B"))
        } else {
            bodyView.visibility = View.GONE
        }
        adView.bodyView = bodyView

        // Advertiser
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        if (nativeAd.advertiser != null) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = View.VISIBLE
            advertiserView.setTextColor(if (isDarkMode) Color.parseColor("#94A3B8") else Color.parseColor("#64748B"))
        } else {
            advertiserView.visibility = View.GONE
        }
        adView.advertiserView = advertiserView

        // Icon
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon?.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }
        adView.iconView = iconView

        // Media
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        if (nativeAd.mediaContent != null) {
            mediaView.mediaContent = nativeAd.mediaContent
            mediaView.visibility = View.VISIBLE
        } else {
            mediaView.visibility = View.GONE
        }
        adView.mediaView = mediaView

        // Call to Action Button
        val ctaButton = adView.findViewById<Button>(R.id.ad_call_to_action)
        if (nativeAd.callToAction != null) {
            ctaButton.text = nativeAd.callToAction
            ctaButton.visibility = View.VISIBLE
            
            // Apply custom button styling
            val buttonBackground = GradientDrawable().apply {
                setColor(buttonColor)
                this.cornerRadius = cornerRadius * context.resources.displayMetrics.density
            }
            ctaButton.background = buttonBackground
            ctaButton.setTextColor(buttonTextColor)
        } else {
            ctaButton.visibility = View.GONE
        }
        adView.callToActionView = ctaButton

        // Set the native ad
        adView.setNativeAd(nativeAd)

        return adView
    }
}
