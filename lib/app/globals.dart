library;

/// Global variable to store deep link detected during AppBootstrapper init.
/// This bypasses GetStorage latency for the immediate splash screen check.
String? pendingInitialDeepLink;

/// Flag: true when an initial deep link was captured by AppBootstrapper.
/// On iOS, app_links fires the same link via BOTH getInitialLink() AND
/// uriLinkStream on cold start. This flag lets _handleDeepLink skip the
/// duplicate to avoid a double-navigation crash.
bool initialDeepLinkHandled = false;
