# Android Release Signing and Firebase Integration Guide

This guide describes how Android release signing is configured for RigLedger, how to maintain the keystore, how to configure key properties, and how to keep Firebase Console synchronized for Google Drive sync.

---

## 1. Overview

RigLedger uses an offline-first architecture with optional Google Drive backup. Google Drive sync relies on Google Sign-In on Android.

For Google Sign-In to succeed in production:
1. The release APK or AAB must be signed with a valid keystore.
2. The SHA-1 certificate fingerprint of the signing key must match the fingerprint registered in the Firebase project console.
3. If fingerprints do not match, Google Sign-In fails with `ApiException: 10` (Developer Error).

---

## 2. Keystore File Location

The production upload keystore must be placed at:

```text
android/app/upload-keystore.jks
```

Both `*.jks` and `android/key.properties` are ignored by git in `.gitignore`. Never commit keystore files or passwords into version control.

### Inspect Keystore Details and SHA Fingerprints

Run the following command to inspect the keystore and view certificate fingerprints:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks
```

To run non-interactively with a known password:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -storepass YOUR_PASSWORD
```

Key values from the output to note:
- **Alias name**: The key alias (for RigLedger, this is `upload`).
- **SHA1**: The SHA-1 fingerprint required by Firebase Console.
- **SHA256**: The SHA-256 fingerprint required for App Links or Play Integrity.

---

## 3. Configuration: `android/key.properties`

Create the file `android/key.properties` in the project root under the `android/` directory:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEYSTORE_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### Explanation of Properties

- `storePassword`: The password unlocking the keystore file.
- `keyPassword`: The password protecting the specific private key inside the keystore (usually identical to `storePassword`).
- `keyAlias`: The alias name of the private key entry (default: `upload`).
- `storeFile`: Path to the `.jks` file. In `android/app/build.gradle`, relative paths resolve against `android/app/`, so `upload-keystore.jks` resolves to `android/app/upload-keystore.jks`.

---

## 4. Firebase Console Setup

Because RigLedger uses Google Sign-In for Drive sync, Firebase needs the SHA-1 fingerprint of the signing key.

### Steps to Register Fingerprint

1. Open the Firebase Console in your browser.
2. Navigate to **Project Settings** (gear icon) > **General**.
3. Under **Your apps**, select the Android app (`com.rigledger.app`).
4. Under **SHA certificate fingerprints**, verify whether the SHA-1 is present:
   - Example SHA-1: `9B:93:B4:41:49:86:63:3C:D9:0E:05:E6:57:4C:E6:24:EA:E7:79:28`
5. If missing, click **Add fingerprint**, paste the SHA-1 value, and click **Save**.

### Play App Signing vs Direct APK

- **Direct Release APK (sideload / manual install):**
  Uses the fingerprint of `android/app/upload-keystore.jks`.
- **Google Play Store distribution (Google Play App Signing enabled):**
  Google Play re-signs the application with its own signing key when distributing via the Play Store.
  You must copy the **App signing key certificate SHA-1** from Google Play Console (**Release** > **Setup** > **App integrity**) and add it to Firebase Console as an additional fingerprint.

---

## 5. Build Commands

Always set `JAVA_HOME` to Java 17 before building:

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
```

### Build Signed Release APK

```bash
flutter build apk --release
```

Output path:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Build Signed Release App Bundle (for Google Play Store upload)

```bash
flutter build appbundle --release
```

Output path:
```text
build/app/outputs/bundle/release/app-release.aab
```

### Verify APK Signature

To verify that an APK has been signed with the expected certificate:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. Common Issues and Fixes

### Issue 1: `SigningConfig "release" is missing required property "storeFile"`
- **Cause:** `android/key.properties` does not exist, or `storeFile` is missing / empty.
- **Fix:** Ensure `android/key.properties` exists and points to a valid file at `android/app/upload-keystore.jks`.

### Issue 2: `keytool error: java.io.IOException: Keystore was tampered with, or password was incorrect`
- **Cause:** Incorrect keystore password entered.
- **Fix:** Verify the password using `keytool -list -keystore <path> -storepass <guess>`.

### Issue 3: Google Drive Sign-In Fails (`ApiException: 10`)
- **Cause:** SHA-1 certificate fingerprint of the APK is not registered in Firebase Console.
- **Fix:**
  1. Inspect the APK's certificate with `apksigner verify --print-certs <path-to-apk>`.
  2. Copy the SHA-1 digest.
  3. Add the SHA-1 digest into Firebase Console under `com.rigledger.app`.
