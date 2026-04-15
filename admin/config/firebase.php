<?php
/**
 * Firebase Helper Class
 * Handles all Firebase Realtime Database operations
 */

class Firebase {
    private $databaseUrl;
    private $apiKey;
    private $serviceAccountPath;
    private $accessToken;
    private $tokenExpiry;
    
    public function __construct() {
        if (!defined('FIREBASE_DATABASE_URL')) {
            require_once __DIR__ . '/config.php';
        }
        $this->databaseUrl = FIREBASE_DATABASE_URL;
        $this->apiKey = FIREBASE_API_KEY;
        $this->serviceAccountPath = defined('FIREBASE_SERVICE_ACCOUNT_KEY')
            ? FIREBASE_SERVICE_ACCOUNT_KEY
            : null;
    }
    
    /**
     * Make HTTP request to Firebase
     */
    private function request($path, $method = 'GET', $data = null) {
        $url = $this->databaseUrl . '/' . $path . '.json';
        $token = $this->getAccessToken();
        
        $headers = ['Content-Type: application/json'];
        if ($token) {
            $headers[] = 'Authorization: Bearer ' . $token;
        }

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        
        switch ($method) {
            case 'POST':
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                break;
            case 'PUT':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                break;
            case 'PATCH':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                break;
            case 'DELETE':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
                break;
        }
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        
        if ($error) {
            return ['success' => false, 'error' => $error, 'httpCode' => $httpCode];
        }
        
        $decoded = json_decode($response, true);
        
        // Check for Firebase error messages
        if ($httpCode >= 400) {
            $errorMsg = 'HTTP Error ' . $httpCode;
            
            if (is_array($decoded)) {
                if (isset($decoded['error'])) {
                    $errorMsg = $decoded['error'];
                } elseif (!empty($response)) {
                    $errorMsg = $response;
                }
            } elseif (is_string($response) && !empty($response)) {
                $errorMsg = $response;
            }
            
            // Common Firebase errors
            if ($httpCode === 401 || (is_string($errorMsg) && stripos($errorMsg, 'permission') !== false)) {
                $errorMsg = 'Permission denied. Please check Firebase service account configuration and security rules.';
            } elseif ($httpCode === 403) {
                $errorMsg = 'Access forbidden. Firebase security rules may be blocking this operation.';
            }
            
            return [
                'success' => false,
                'error' => is_string($errorMsg) ? $errorMsg : json_encode($errorMsg),
                'httpCode' => $httpCode,
                'data' => null
            ];
        }
        
        return [
            'success' => $httpCode >= 200 && $httpCode < 300,
            'data' => $decoded,
            'httpCode' => $httpCode
        ];
    }

    /**
     * Get OAuth access token using service account (if available)
     */
    private function getAccessToken() {
        if (empty($this->serviceAccountPath)) {
            error_log('Firebase: Service account path not configured in config.php');
            return null;
        }
        
        if (!file_exists($this->serviceAccountPath)) {
            error_log('Firebase: Service account file not found at: ' . $this->serviceAccountPath);
            error_log('Firebase: Please ensure the service account JSON file is uploaded to the server');
            return null;
        }

        if ($this->accessToken && $this->tokenExpiry && time() < ($this->tokenExpiry - 60)) {
            return $this->accessToken;
        }

        $serviceAccount = json_decode(file_get_contents($this->serviceAccountPath), true);
        if (
            empty($serviceAccount['client_email']) ||
            empty($serviceAccount['private_key'])
        ) {
            error_log('Firebase: Service account file missing client_email or private_key');
            return null;
        }

        // Format private key properly (handle escaped newlines)
        $privateKey = $serviceAccount['private_key'];
        if (strpos($privateKey, '\\n') !== false) {
            $privateKey = str_replace('\\n', "\n", $privateKey);
        }

        $jwt = $this->createJwt(
            $serviceAccount['client_email'],
            $privateKey
        );
        if (!$jwt) {
            return null;
        }

        return $this->fetchAccessToken($jwt);
    }

    private function createJwt($clientEmail, $privateKey) {
        $now = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $payload = [
            'iss' => $clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ];

        $segments = [
            $this->base64UrlEncode(json_encode($header)),
            $this->base64UrlEncode(json_encode($payload)),
        ];
        $signingInput = implode('.', $segments);

        $signature = '';
        $signed = openssl_sign($signingInput, $signature, $privateKey, 'sha256');
        if (!$signed) {
            return null;
        }

        $segments[] = $this->base64UrlEncode($signature);
        return implode('.', $segments);
    }

    private function fetchAccessToken($jwt) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/x-www-form-urlencoded'
        ]);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt
        ]));

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($error) {
            error_log('Firebase: OAuth token fetch error: ' . $error);
            return null;
        }

        if ($httpCode !== 200 || !$response) {
            error_log('Firebase: OAuth token fetch failed. HTTP Code: ' . $httpCode . ', Response: ' . $response);
            return null;
        }

        $data = json_decode($response, true);
        if (empty($data['access_token']) || empty($data['expires_in'])) {
            error_log('Firebase: Invalid OAuth response: ' . $response);
            return null;
        }

        $this->accessToken = $data['access_token'];
        $this->tokenExpiry = time() + (int)$data['expires_in'];
        return $this->accessToken;
    }

    private function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    
    /**
     * Get data from Firebase
     */
    public function get($path) {
        return $this->request($path, 'GET');
    }
    
    /**
     * Push new data to Firebase (generates unique key)
     */
    public function push($path, $data) {
        return $this->request($path, 'POST', $data);
    }
    
    /**
     * Set/replace data at specific path
     */
    public function set($path, $data) {
        return $this->request($path, 'PUT', $data);
    }
    
    /**
     * Update specific fields at path
     */
    public function update($path, $data) {
        return $this->request($path, 'PATCH', $data);
    }
    
    /**
     * Delete data at path
     */
    public function delete($path) {
        return $this->request($path, 'DELETE');
    }
    
    // ==================== VIDEO METHODS ====================
    
    /**
     * Get all videos
     */
    public function getVideos() {
        $result = $this->get('videos');
        if ($result['success'] && $result['data']) {
            $videos = [];
            foreach ($result['data'] as $id => $video) {
                $video['id'] = $id;
                $videos[] = $video;
            }
            return ['success' => true, 'data' => $videos];
        }
        return ['success' => true, 'data' => []];
    }
    
    /**
     * Add new video
     */
    public function addVideo($title, $subTitle, $videoUrl) {
        $data = [
            'title' => $title,
            'sub_title' => $subTitle,
            'video_url' => $videoUrl,
            'created_at' => date('c')
        ];
        return $this->push('videos', $data);
    }
    
    /**
     * Update video
     */
    public function updateVideo($id, $title, $subTitle, $videoUrl) {
        $data = [
            'title' => $title,
            'sub_title' => $subTitle,
            'video_url' => $videoUrl,
            'updated_at' => date('c')
        ];
        return $this->update('videos/' . $id, $data);
    }
    
    /**
     * Delete video
     */
    public function deleteVideo($id) {
        return $this->delete('videos/' . $id);
    }
    
    // ==================== AD CONFIG METHODS ====================
    
    /**
     * Get ad configuration
     */
    public function getAdConfig() {
        $result = $this->get('ad_config');
        if ($result['success'] && $result['data']) {
            return ['success' => true, 'data' => $result['data']];
        }
        // Return default config if not exists
        return ['success' => true, 'data' => $this->getDefaultAdConfig()];
    }
    
    /**
     * Update ad configuration
     */
    public function updateAdConfig($config) {
        return $this->set('ad_config', $config);
    }
    
    /**
     * Get default ad configuration
     */
    private function getDefaultAdConfig() {
        return [
            'showBannerAd' => true,
            'showNativeAd' => true,
            'showInterstitialAd' => true,
            'showRewardedAd' => true,
            'showAppOpenAd' => true,
            'bannerAdId' => '',
            'nativeAdId' => '',
            'interstitialAdId' => '',
            'rewardedAdId' => '',
            'appOpenAdId' => '',
            'nativeButtonColor' => 0xFF8B5CF6,
            'nativeButtonTextColor' => 0xFFFFFFFF,
            'nativeBackgroundColor' => 0xFFFFFFFF,
            'nativeBackgroundColorDark' => 0xFF1A1A24,
            'nativeCornerRadius' => 12.0,
            'nativeAdFactoryId' => 'mediumNativeAd',
            'interstitialCooldownSeconds' => 1,
            'appOpenCooldownSeconds' => 30,
            'preloadAdCount' => 2,
            'adLoadTimeoutSeconds' => 30,
            'shimmerBaseLight' => 0xFFE2E8F0,
            'shimmerHighlightLight' => 0xFFF1F5F9,
            'shimmerBaseDark' => 0xFF2D2D3A,
            'shimmerHighlightDark' => 0xFF3D3D4A,
            'nativeAdShimmerHeight' => 280.0,
            'bannerAdShimmerHeight' => 60.0
        ];
    }
    
    // ==================== API CONFIG METHODS ====================
    
    /**
     * Get API configuration (Gemini, etc.)
     */
    public function getApiConfig() {
        $result = $this->get('api_config');
        if ($result['success'] && $result['data']) {
            return ['success' => true, 'data' => $result['data']];
        }
        return ['success' => true, 'data' => $this->getDefaultApiConfig()];
    }
    
    /**
     * Update API configuration
     */
    public function updateApiConfig($config) {
        return $this->set('api_config', $config);
    }
    
    /**
     * Get default API configuration
     */
    private function getDefaultApiConfig() {
        return [
            'geminiApiKey' => '',
            'geminiModel' => 'gemini-2.5-flash',
            'analysisPrompt' => '',
            'playStoreUrl' => '',
            'appStoreUrl' => '',
            'moreAppsUrl' => '',
            'privacyPolicyUrl' => '',
            'termsOfServiceUrl' => '',
            'supportEmail' => ''
        ];
    }
    
    // ==================== IAP CONFIG METHODS ====================
    
    /**
     * Get IAP configuration
     */
    public function getIAPConfig() {
        $result = $this->get('iap_config');
        if ($result['success'] && $result['data']) {
            return ['success' => true, 'data' => $result['data']];
        }
        return ['success' => true, 'data' => $this->getDefaultIAPConfig()];
    }
    
    /**
     * Update IAP configuration (uses PATCH so it does NOT overwrite
     * iap_config/plans and iap_config/subscription_plans).
     */
    public function updateIAPConfig($config) {
        return $this->update('iap_config', $config);
    }
    
    /**
     * Get default IAP configuration
     */
    private function getDefaultIAPConfig() {
        return [
            'enableIAP' => true,
            'freeCredits' => 5,
            'creditsPerAnalysis' => 1,
            'showUpgradePrompt' => true
        ];
    }
    
    /**
     * Diagnostic method to check Firebase configuration
     */
    public function checkConfiguration() {
        $issues = [];
        $warnings = [];
        
        // Check service account file
        if (empty($this->serviceAccountPath)) {
            $issues[] = 'Service account path not configured in config.php';
        } elseif (!file_exists($this->serviceAccountPath)) {
            $issues[] = 'Service account file not found at: ' . $this->serviceAccountPath;
            $warnings[] = 'Please upload the Firebase service account JSON file to the server';
        } else {
            // Try to read and validate service account
            $serviceAccount = @json_decode(file_get_contents($this->serviceAccountPath), true);
            if (!$serviceAccount) {
                $issues[] = 'Service account file is invalid JSON';
            } elseif (empty($serviceAccount['client_email']) || empty($serviceAccount['private_key'])) {
                $issues[] = 'Service account file missing client_email or private_key';
            } else {
                // Try to get access token
                $token = $this->getAccessToken();
                if (!$token) {
                    $warnings[] = 'Unable to generate access token. Check service account permissions and Firebase project settings.';
                }
            }
        }
        
        // Check database URL
        if (empty($this->databaseUrl)) {
            $issues[] = 'Firebase database URL not configured';
        }
        
        return [
            'configured' => empty($issues),
            'issues' => $issues,
            'warnings' => $warnings,
            'serviceAccountExists' => !empty($this->serviceAccountPath) && file_exists($this->serviceAccountPath),
            'canAuthenticate' => !empty($this->getAccessToken())
        ];
    }
}
?>
