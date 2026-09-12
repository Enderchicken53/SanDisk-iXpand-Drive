# iXpand Drive rebuild kit

This kit prepares SanDisk's public iXpand Drive object-code repository for an experimental modern-Xcode build.

IMPORTANT:
- This does NOT contain SanDisk's 68 MB `iXpand Drive.a`; the official repository supplies it.
- It does NOT contain an IPA or signing credentials.
- The original SanDisk build script targets armv7 + arm64, iOS 8.2, and libstdc++. Modern Xcode no longer supports all of those settings, so this kit attempts an arm64-only build using the SDK installed on the runner/Mac.
- Build success is NOT guaranteed. The bundled third-party libraries may themselves be too old for a modern SDK.
- If the build succeeds, the result is an UNSIGNED IPA suitable for signing with your own Apple development identity (for example with Sideloadly).

## Easiest route

1. Fork:
   https://github.com/SanDisk-Open-Source/SanDisk-iXpand-Drive
2. Copy `.github/workflows/build.yml` from this kit into your fork.
3. Push it to your fork.
4. Open GitHub -> Actions -> `Build iXpand Drive`.
5. Run the workflow manually.
6. Download the `iXpand-unsigned` artifact.
7. Sign the resulting IPA with your own Apple ID using Sideloadly.

## What this changes

The original SanDisk script:
- uses `/Applications/Xcode.app`
- requests armv7 + arm64
- requests `-stdlib=libstdc++`
- copies a provisioning profile that is not present in the current public repository
- signs using an empty placeholder identity

This experimental script:
- discovers the selected Xcode path
- builds arm64 only
- removes the obsolete `-stdlib=libstdc++` compiler option
- does not require SanDisk's old provisioning profile
- leaves the app unsigned
- packages `Payload/iXpand Drive.app` as an IPA

The `ExternalAccessory` framework is retained because it is part of the original SanDisk link command and is relevant to Lightning accessory communication.

## If it fails

The first useful failure is likely to be one of:
- old object files/libraries incompatible with the installed SDK
- missing old symbols from libstdc++
- obsolete framework names
- architecture mismatch
- code-signing/entitlement problems after signing

The workflow uploads `build.log` even on failure.
