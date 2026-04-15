<?php
/**
 * OneSignal Helper Class
 * Handles all OneSignal Push Notification operations
 */

class OneSignal {
    private $appId;
    private $restApiKey;
    private $apiUrl = 'https://onesignal.com/api/v1';
    
    public function __construct() {
        $this->appId = ONESIGNAL_APP_ID;
        $this->restApiKey = ONESIGNAL_REST_API_KEY;
    }
    
    /**
     * Make HTTP request to OneSignal
     */
    private function request($endpoint, $method = 'GET', $data = null) {
        $url = $this->apiUrl . '/' . $endpoint;
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json; charset=utf-8',
            'Authorization: Basic ' . $this->restApiKey
        ]);
        
        switch ($method) {
            case 'POST':
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
                break;
            case 'PUT':
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
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
            return ['success' => false, 'error' => $error];
        }
        
        return [
            'success' => $httpCode >= 200 && $httpCode < 300,
            'data' => json_decode($response, true),
            'httpCode' => $httpCode
        ];
    }
    
    /**
     * Send notification to all users
     */
    public function sendToAll($title, $message, $data = [], $imageUrl = null) {
        $payload = [
            'app_id' => $this->appId,
            'included_segments' => ['All'],
            'headings' => ['en' => $title],
            'contents' => ['en' => $message],
            'data' => $data
        ];
        
        if ($imageUrl) {
            $payload['big_picture'] = $imageUrl;
            $payload['ios_attachments'] = ['id' => $imageUrl];
        }
        
        return $this->request('notifications', 'POST', $payload);
    }
    
    /**
     * Send notification to specific segment
     */
    public function sendToSegment($segment, $title, $message, $data = [], $imageUrl = null) {
        $payload = [
            'app_id' => $this->appId,
            'included_segments' => [$segment],
            'headings' => ['en' => $title],
            'contents' => ['en' => $message],
            'data' => $data
        ];
        
        if ($imageUrl) {
            $payload['big_picture'] = $imageUrl;
            $payload['ios_attachments'] = ['id' => $imageUrl];
        }
        
        return $this->request('notifications', 'POST', $payload);
    }
    
    /**
     * Send notification to specific users by player IDs
     */
    public function sendToUsers($playerIds, $title, $message, $data = [], $imageUrl = null) {
        $payload = [
            'app_id' => $this->appId,
            'include_player_ids' => $playerIds,
            'headings' => ['en' => $title],
            'contents' => ['en' => $message],
            'data' => $data
        ];
        
        if ($imageUrl) {
            $payload['big_picture'] = $imageUrl;
            $payload['ios_attachments'] = ['id' => $imageUrl];
        }
        
        return $this->request('notifications', 'POST', $payload);
    }
    
    /**
     * Schedule notification
     */
    public function scheduleNotification($title, $message, $sendAt, $segment = 'All', $data = [], $imageUrl = null) {
        $payload = [
            'app_id' => $this->appId,
            'included_segments' => [$segment],
            'headings' => ['en' => $title],
            'contents' => ['en' => $message],
            'send_after' => $sendAt,
            'data' => $data
        ];
        
        if ($imageUrl) {
            $payload['big_picture'] = $imageUrl;
            $payload['ios_attachments'] = ['id' => $imageUrl];
        }
        
        return $this->request('notifications', 'POST', $payload);
    }
    
    /**
     * Get app information including player count
     */
    public function getAppInfo() {
        return $this->request('apps/' . $this->appId);
    }
    
    /**
     * Get notification history
     */
    public function getNotifications($limit = 50, $offset = 0) {
        return $this->request("notifications?app_id={$this->appId}&limit={$limit}&offset={$offset}");
    }
    
    /**
     * Get notification by ID
     */
    public function getNotification($notificationId) {
        return $this->request("notifications/{$notificationId}?app_id={$this->appId}");
    }
    
    /**
     * Cancel scheduled notification
     */
    public function cancelNotification($notificationId) {
        return $this->request("notifications/{$notificationId}?app_id={$this->appId}", 'DELETE');
    }
    
    /**
     * Get segments
     */
    public function getSegments() {
        // OneSignal doesn't have a direct API for listing segments
        // Return common default segments
        return [
            'success' => true,
            'data' => [
                ['name' => 'All', 'description' => 'All subscribed users'],
                ['name' => 'Active Users', 'description' => 'Users active in last 24 hours'],
                ['name' => 'Inactive Users', 'description' => 'Users inactive for 7+ days'],
                ['name' => 'Subscribed Users', 'description' => 'Users with active subscriptions'],
                ['name' => 'Free Users', 'description' => 'Users on free plan']
            ]
        ];
    }
}
?>
