<?php
// delete.php
// ChartSense AI - Account & Data Deletion Request Page

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = trim($_POST['email']);

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = "Please enter a valid email address.";
    } else {
        // OPTIONAL: Save request to database / email / log file
        // file_put_contents("delete_requests.txt", $email . " | " . date("Y-m-d H:i:s") . PHP_EOL, FILE_APPEND);

        $success = true;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Account Deletion Request – ChartSense AI</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #0f1220;
            color: #ffffff;
            padding: 20px;
        }
        .container {
            max-width: 520px;
            margin: auto;
            background: #1a1d3a;
            padding: 25px;
            border-radius: 10px;
        }
        h1 {
            color: #9b7cff;
        }
        input, button {
            width: 100%;
            padding: 12px;
            margin-top: 12px;
            border-radius: 6px;
            border: none;
            font-size: 15px;
        }
        input {
            background: #2a2d55;
            color: #fff;
        }
        button {
            background: #9b7cff;
            color: #000;
            font-weight: bold;
            cursor: pointer;
        }
        .success {
            background: #1e7e34;
            padding: 12px;
            border-radius: 6px;
            margin-top: 15px;
        }
        .error {
            background: #b02a37;
            padding: 12px;
            border-radius: 6px;
            margin-top: 15px;
        }
        .info {
            font-size: 14px;
            opacity: 0.9;
            margin-top: 15px;
        }
    </style>
</head>
<body>

<div class="container">
    <h1>Account & Data Deletion</h1>

    <p>
        If you want to delete your <b>ChartSense AI</b> account and associated data,
        please submit your registered email address below.
    </p>

    <?php if (!empty($success)): ?>
        <div class="success">
            ✅ Your deletion request has been received.<br>
            Our team will process it within <b>7–30 days</b>.
        </div>
    <?php elseif (!empty($error)): ?>
        <div class="error">
            ❌ <?php echo $error; ?>
        </div>
    <?php endif; ?>

    <form method="POST">
        <input type="email" name="email" placeholder="Enter your registered email" required>
        <button type="submit">Request Account Deletion</button>
    </form>

    <div class="info">
        <p><b>What data will be deleted:</b></p>
        <ul>
            <li>User account (email & profile)</li>
            <li>Login credentials</li>
            <li>Scan history & analysis data</li>
            <li>Subscription status (if any)</li>
        </ul>

        <p>
            Some data may be retained for up to <b>90 days</b> for legal, security,
            or fraud prevention purposes, after which it is permanently deleted.
        </p>

        <p>
            Support: <a href="mailto:support@smartpricetracker.in" style="color:#9b7cff;">
                support@smartpricetracker.in
            </a>
        </p>
    </div>
</div>

</body>
</html>