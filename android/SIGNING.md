# Setting up a permanent release signing key

Right now your APK is signed with Flutter's auto-generated debug key, which is
**different on every machine and every fresh CI runner**. That's why installing
a new build over an old one shows "package conflict" — Android treats
differently-signed builds as different apps.

Do this **once**. After that, every build (local or CI) will share the same
signature, and updates will install cleanly without losing your saved
invoices.

## 1. Generate a keystore (do this on your own machine, not in CI)

You need a JDK installed. Then run:

```bash
keytool -genkey -v -keystore invois-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias invois
```

It'll ask for a store password, a key password (can be the same), and some
name/org fields — those don't matter functionally. **Keep the resulting
`invois-release.jks` file and both passwords somewhere safe** (password
manager). If you lose this keystore, you can never publish an update to the
same app again — you'd have to ship under a new package ID.

## 2. Local builds (optional, only needed if you build APKs on your own machine)

Put the `.jks` file somewhere outside the repo (e.g. `~/keys/invois-release.jks`),
then create `android/key.properties` (this file is gitignored, never commit it):

```properties
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=invois
storeFile=/absolute/path/to/invois-release.jks
```

That's it — `flutter build apk --release` will now use it automatically.

## 3. GitHub Actions builds

CI can't read a file from your machine, so the keystore and passwords are
passed in as **GitHub Secrets**, then written to disk right before the build
step.

### Add the secrets
In your repo: **Settings → Secrets and variables → Actions → New repository secret**.
Add these four:

| Secret name | Value |
|---|---|
| `KEYSTORE_BASE64` | output of `base64 -i invois-release.jks \| tr -d '\n'` |
| `KEYSTORE_PASSWORD` | your store password |
| `KEY_PASSWORD` | your key password |
| `KEY_ALIAS` | `invois` (or whatever alias you used) |

### Updated workflow
See `.github/workflows/build-apk.yml` — it now decodes `KEYSTORE_BASE64` into
`android/app/invois-release.jks` and writes `android/key.properties` from the
other three secrets, before running `flutter build apk --release`.

Once this is set up, every APK — whether built on your laptop or by GitHub
Actions — will carry the same signature, and installing a new version will
correctly update the old one in place.
