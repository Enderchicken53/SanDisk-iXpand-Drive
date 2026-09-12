#!/usr/bin/env bash
set -euo pipefail

APP="app/iXpand Drive.app"
OUT="iXpand-unsigned.ipa"

echo "== Xcode =="
XCODE_BASE="$(xcode-select -p | sed 's#/Contents/Developer$##')"
echo "XCODE_BASE=$XCODE_BASE"
xcodebuild -version
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "SDK=$SDK"

if [ ! -f "iXpand Drive.a" ]; then
  echo "ERROR: iXpand Drive.a is missing."
  exit 2
fi

if [ ! -d "$APP" ]; then
  echo "ERROR: $APP is missing."
  exit 2
fi

# The public repository's original script copies an old provisioning profile.
# The current public tree does not expose that profile, and we want an unsigned
# build that can later be signed by the user's own identity.
rm -f "$APP/embedded.mobileprovision"
rm -rf "$APP/_CodeSignature"
rm -f "$APP/iXpand Drive"

# Copy the repository metadata that the original script uses.
cp Info.plist "$APP/Info.plist"
if [ -f GoogleService-Info.plist ]; then
  cp GoogleService-Info.plist "$APP/GoogleService-Info.plist"
fi

CLANG="$XCODE_BASE/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

echo "== Linking arm64 =="
"$CLANG" \
  -std=c++11 \
  -arch arm64 \
  -isysroot "$SDK" \
  "iXpand Drive.a" \
  -dead_strip -ObjC \
  -Llib -Fframeworks \
  -l"AFNetworking" -l"BlocksKit" -l"Bolts" -l"CSStickyHeaderFlowLayout" \
  -l"CocoaAsyncSocket" -l"CocoaHTTPServer" -l"CocoaLumberjack" -l"DFCache" \
  -l"FBSDKCoreKit" -l"FBSDKLoginKit" -l"FXKeychain" -l"GGLCore" -l"GGLSignIn" \
  -l"GIPNSURL+FIFE_external" -l"GSDK_Overload_external" \
  -l"GTMOAuth2_external_external" -l"GTMOAuth2_internal_external" \
  -l"GTMSessionFetcher_core_external" -l"GTMSessionFetcher_full_external" \
  -l"GTMStackTrace_external" -l"GTM_AddressBook_external" \
  -l"GTM_DebugUtils_external" -l"GTM_GTMURLBuilder_external" -l"GTM_KVO_external" \
  -l"GTM_NSData+zlib" -l"GTM_NSDictionary+URLArguments_external" \
  -l"GTM_NSScannerJSON_external" -l"GTM_NSStringHTML_external" \
  -l"GTM_NSStringXML_external" -l"GTM_Regex_external" \
  -l"GTM_RoundedRectPath_external" -l"GTM_StringEncoding_external" \
  -l"GTM_SystemVersion_external" -l"GTM_UIFont+LineHeight_external" \
  -l"GTM_core_external" -l"GTM_iPhone_external" -l"InstagramKit" \
  -l"LocalyticsAMP_x64" -l"NSLogger" -l"NSLogger-CocoaLumberjack-connector" \
  -l"OpenInChrome_external" -l"ProtocolBuffers_external" -l"RFQuiltLayout" \
  -l"RHAddressBook" -l"Reachability" -l"SSZipArchive" -l"SVWebViewController" \
  -l"SignIn_external" -l"UICKeyChainStore" -l"apptentive-ios" -l"bz2" \
  -l"c++" -l"iconv" -l"sqlite3" -l"stdc++" -l"xml2" -l"z" \
  -framework "AVFoundation" -framework "AddressBook" -framework "AddressBookUI" \
  -framework "AssetsLibrary" -framework "AudioToolbox" -framework "CFNetwork" \
  -framework "CoreData" -framework "CoreFoundation" -framework "CoreGraphics" \
  -framework "CoreLocation" -framework "CoreMotion" -framework "CoreText" \
  -framework "Crashlytics" -framework "Fabric" -framework "Foundation" \
  -framework "HockeySDK" -framework "ImageIO" -framework "MessageUI" \
  -framework "MobileCoreServices" -framework "MobileVLCKit" -framework "OpenGLES" \
  -framework "QuartzCore" -framework "QuickLook" -framework "SafariServices" \
  -framework "Security" -framework "SystemConfiguration" -framework "UIKit" \
  -weak_framework "Accounts" -weak_framework "AdSupport" \
  -weak_framework "AudioToolbox" -weak_framework "CoreGraphics" \
  -weak_framework "CoreLocation" -weak_framework "CoreTelephony" \
  -weak_framework "Foundation" -weak_framework "QuartzCore" \
  -weak_framework "Security" -weak_framework "Social" -weak_framework "StoreKit" \
  -weak_framework "UIKit" \
  -framework "CoreData" -framework "ExternalAccessory" -framework "MediaPlayer" \
  -fobjc-link-runtime \
  -miphoneos-version-min=8.2 \
  -o "$APP/iXpand Drive"

echo "== Verify executable =="
file "$APP/iXpand Drive" || true
xcrun otool -L "$APP/iXpand Drive" | sed -n '1,160p' || true

echo "== Prepare IPA =="
rm -rf Payload
mkdir Payload
cp -R "$APP" "Payload/iXpand Drive.app"

rm -f "$OUT"
/usr/bin/zip -qry "$OUT" Payload

echo
echo "SUCCESS: $OUT"
echo "This IPA is unsigned."
