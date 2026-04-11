/// Consent Service
/// Handles GDPR / EEA / UK consent using Google's UMP SDK (built into google_mobile_ads).
/// The UMP SDK automatically detects the user's region and only shows the consent
/// form to users in countries where it is required (EEA, UK, Switzerland).
/// Non-EEA users are never shown the form.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  static ConsentService? _instance;
  static ConsentService get instance => _instance ??= ConsentService._();

  ConsentService._();

  bool _consentFlowCompleted = false;
  bool _canRequestAds = true;

  /// Whether the UMP consent flow has finished (form shown or not required).
  bool get consentFlowCompleted => _consentFlowCompleted;

  /// Whether we are allowed to request ads based on user consent.
  bool get canRequestAds => _canRequestAds;

  Future<void> _refreshCanRequestAds() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      _canRequestAds = true;
    }
  }

  /// Requests consent info update from Google and shows the GDPR consent form
  /// if the user is in an eligible region (EEA / UK / Switzerland).
  /// Non-EEA users will not see any form — completes silently.
  ///
  /// Includes a 15-second timeout to avoid blocking app startup on slow networks.
  Future<void> requestConsentAndShowFormIfRequired() async {
    if (kIsWeb) {
      debugPrint('ConsentService: Web platform — skipping UMP consent');
      _consentFlowCompleted = true;
      return;
    }

    try {
      final completer = Completer<void>();

      final params = ConsentRequestParameters(
        tagForUnderAgeOfConsent: false,
      );

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () {
          debugPrint('ConsentService: Consent info updated successfully');

          ConsentForm.loadAndShowConsentFormIfRequired(
            (FormError? error) async {
              if (error != null) {
                debugPrint(
                  'ConsentService: Consent form error: ${error.message}',
                );
              } else {
                debugPrint(
                  'ConsentService: Consent form completed or not required',
                );
              }
              await _refreshCanRequestAds();
              _consentFlowCompleted = true;
              debugPrint('ConsentService: canRequestAds = $_canRequestAds');
              if (!completer.isCompleted) completer.complete();
            },
          );
        },
        (FormError error) async {
          debugPrint(
            'ConsentService: requestConsentInfoUpdate failed: ${error.message}',
          );
          await _refreshCanRequestAds();
          _consentFlowCompleted = true;
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('ConsentService: Consent flow timed out after 15s');
          _consentFlowCompleted = true;
        },
      );
    } catch (e) {
      debugPrint('ConsentService: Error during consent flow: $e');
      _consentFlowCompleted = true;
    }
  }

  /// Shows the privacy options form so users can change their consent choices.
  /// Call this from a "Privacy Settings" button in your app's Settings screen.
  Future<void> showPrivacyOptionsForm() async {
    if (kIsWeb) return;
    try {
      final completer = Completer<void>();
      ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (error != null) {
          debugPrint(
            'ConsentService: Privacy options form error: ${error.message}',
          );
        }
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('ConsentService: Privacy options form timed out');
        },
      );
    } catch (e) {
      debugPrint('ConsentService: showPrivacyOptionsForm error: $e');
    }
  }

  /// Resets consent info (for debugging only). Users will see the form again.
  void resetConsent() {
    ConsentInformation.instance.reset();
    _consentFlowCompleted = false;
    debugPrint('ConsentService: Consent info reset');
  }
}
