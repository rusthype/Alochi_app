# Release Signing Setup — A'lochi Ustoz

## 1. Generate the keystore (run ONCE, keep the file forever)

```bash
keytool -genkey -v \
  -keystore ~/alochi-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias alochi
```

The tool will prompt for:
- **Keystore password** — choose a strong password, save it immediately (see backup section)
- **Key password** — can be the same as keystore password
- **Distinguished name fields** — at minimum set CN (your name or org), C (country code e.g. UZ)

## 2. Where to store the .jks file

- **DO NOT** place it inside the repository. The file is listed in `android/.gitignore` and must never be committed.
- Default safe path: `~/alochi-release.jks` (your home directory, outside the repo)
- On CI/CD: inject as a base64-encoded environment secret and decode before build

## 3. Backup strategy

Store **all three** of the following in a secure location before closing the terminal:

| Item | Where to back up |
|---|---|
| `~/alochi-release.jks` file | 1Password (attach as file) or Google Drive private folder (access restricted) |
| Keystore password | 1Password secure note titled "alochi-release keystore" |
| Key password | Same 1Password secure note |

Losing the keystore means you can never update the app on Play Console. There is no recovery.

## 4. What to remember

| Field | Value |
|---|---|
| Key alias | `alochi` |
| Keystore file | `~/alochi-release.jks` (adjust path if stored elsewhere) |
| Keystore password | set during keytool generation — see 1Password |
| Key password | set during keytool generation — see 1Password |

## 5. Create android/key.properties

Copy the example file and fill in real values:

```bash
cp android/key.properties.example android/key.properties
# Edit android/key.properties with real passwords and the absolute path to your .jks
```

`android/key.properties` is gitignored and must never be committed.

## 6. Build the release bundle

After placing `android/key.properties` with correct values:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload this `.aab` file to Google Play Console.

## 7. Verifying the signature

```bash
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/release/app-release.aab
```
