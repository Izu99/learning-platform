# Debug Report: Gradle Build Failure (Android)

## Symptom
`flutter run` fails with "Execution failed for task ':app:checkDebugAarMetadata'". The core error is `Could not parse POM... Content is not allowed in prolog.` for `flutter_embedding_debug`.

## Root Cause Hypothesis
This error almost always points to a corrupted or incomplete dependency file in the local Gradle cache. A network interruption during a previous download can leave a malformed `.pom` file (like an empty file or an HTML error page instead of XML). When Gradle tries to parse this invalid file, it fails with the "Content is not allowed in prolog" error because the file isn't valid XML.

## Fix Proposal
The most reliable fix is to force Gradle to re-download the corrupted dependency by clearing the cache.

**Instructions for Developer:**
1.  **Stop any running builds.**
2.  **Navigate to the `client/` directory.**
3.  **Run `flutter clean`** to remove Flutter's build artifacts.
4.  **Run `flutter pub get`** to ensure dependencies are re-linked.
5.  **Manually clear Gradle cache (if needed):**
    *   On Windows, this is typically in `C:\Users\<YourUser>\.gradle\caches`. Deleting this folder is safe.
    *   Alternatively, use the `./gradlew cleanBuildCache` command from within the `client/android` directory.
6.  **Re-run the app:** `flutter run`.

## Verification Plan
1.  Apply the fix steps.
2.  Run `flutter run`.
3.  Confirm that the Gradle task `assembleDebug` completes successfully and the app launches on the emulator.
