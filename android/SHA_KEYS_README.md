# Release APK – SHA-1 and SHA-256

Use these for **Firebase**, **Google Sign-In**, **Google Play App Signing**, or any API that needs your app’s signing certificate fingerprints.

---

## Option 1: Run the batch script (Windows)

1. Open **Command Prompt** or **PowerShell**.
2. Go to the `android` folder:
   ```bash
   cd c:\Users\Tushar\Downloads\StockAi\ChartSenseAI\android
   ```
3. Run:
   ```bash
   get_sha_release.bat
   ```
4. When asked, enter your **keystore password** and **key password** (from `key.properties`).
5. In the output, find:
   - **SHA1:** `AA:BB:CC:...`
   - **SHA-256:** `XX:YY:ZZ:...`

Copy those values where needed (e.g. Firebase Console → Project settings → Your apps → Add fingerprint).

---

## Option 2: Gradle signing report

From the project root:

```bash
cd android
.\gradlew signingReport
```

Or from the **android** folder:

```bash
.\gradlew signingReport
```

In the report, under **Variant: release**, you’ll see **SHA-1** and **SHA-256** for the release keystore.

---

## Option 3: keytool (manual)

If you know your keystore path, alias, and passwords:

```bash
keytool -list -v -keystore "PATH_TO_YOUR_KEYSTORE.jks" -alias YOUR_ALIAS
```

Example (keystore in `android` folder, alias `upload`):

```bash
keytool -list -v -keystore android\upload-keystore.jks -alias upload
```

You’ll be prompted for:
- Keystore password  
- Key password (if different)

In the output, use the **SHA1** and **SHA-256** lines.

**keytool** is in your JDK (e.g. `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`). Add that folder to PATH or use the full path.

---

## Where to use these

| Use              | Where |
|------------------|--------|
| Firebase         | Project settings → Your apps → Android app → Add fingerprint (SHA-1 and/or SHA-256). |
| Google Sign-In   | Same as Firebase if you use Firebase Auth; or Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 → Add fingerprint. |
| Play Console     | Release → Setup → App signing: upload key certificate fingerprints (if you use Play App Signing, Play may show these for you). |

---

**Note:** `key.properties` is gitignored. Never commit it or your keystore file.
