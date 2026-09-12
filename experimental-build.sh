#!/bin/bash
set -e

echo "== iXpand Drive experimental build =="

XCODE_BASE="$(xcode-select -p | sed 's#/Contents/Developer##')"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos -f clang)"

echo "XCODE_BASE=$XCODE_BASE"
echo "SDK=$SDK"
echo "CLANG=$CLANG"

RESULT_DIR="app/iXpand Drive.app"
MVLC_DIR="frameworks/MobileVLCKit.framework"

if [ ! -f "iXpand Drive.a" ]; then
  echo "ERROR: iXpand Drive.a not found"
  exit 1
fi

if [ ! -d "$RESULT_DIR" ]; then
  echo "ERROR: app bundle not found: $RESULT_DIR"
  exit 1
fi

echo
echo "== Input architectures =="
file "iXpand Drive.a"
lipo -info "iXpand Drive.a" || true

echo
echo "== Library directory =="
find lib -maxdepth 1 -type f | sort

echo
echo "== Framework directory =="
find frameworks -maxdepth 2 -type f | sort

echo
echo "== Preparing app bundle =="

rm -f "$RESULT_DIR/iXpand Drive"
rm -rf "$RESULT_DIR/_CodeSignature"
rm -f "$RESULT_DIR/embedded.mobileprovision"

[ -f "Info.plist" ] && cp "Info.plist" "$RESULT_DIR/Info.plist"
[ -f "GoogleService-Info.plist" ] && cp "GoogleService-Info.plist" "$RESULT_DIR/GoogleService-Info.plist"

echo
echo "== Preparing MobileVLCKit =="

MVLC_PART1="$MVLC_DIR/MobileVLCKit.7z.001"
MVLC_PART2="$MVLC_DIR/MobileVLCKit.7z.002"
MVLC_PART3="$MVLC_DIR/MobileVLCKit.7z.003"
MVLC_BINARY="$MVLC_DIR/MobileVLCKit"

if [ ! -f "$MVLC_BINARY" ]; then
  for part in "$MVLC_PART1" "$MVLC_PART2" "$MVLC_PART3"; do
    if [ ! -f "$part" ]; then
      echo "ERROR: missing MobileVLCKit archive part: $part"
      exit 1
    fi
  done

  if ! command -v 7z >/dev/null 2>&1; then
    echo "7z not found; installing sevenzip..."
    brew install sevenzip
  fi

  command -v 7z >/dev/null 2>&1 || {
    echo "ERROR: 7z is still unavailable after installation."
    exit 1
  }

  TMP_MVLC="$(mktemp -d)"
  trap 'rm -rf "$TMP_MVLC"' EXIT

  echo "Extracting MobileVLCKit..."
  7z x "$MVLC_PART1" -o"$TMP_MVLC" -y

  echo
  echo "== Extracted MobileVLCKit contents =="
  find "$TMP_MVLC" -maxdepth 7 -print | sort

  NESTED_FRAMEWORK="$(find "$TMP_MVLC" -type d -name 'MobileVLCKit.framework' -print -quit || true)"

  if [ -n "$NESTED_FRAMEWORK" ]; then
    echo "Found nested framework: $NESTED_FRAMEWORK"
    for item in Headers Modules Resources Info.plist; do
      if [ -e "$NESTED_FRAMEWORK/$item" ]; then
        rm -rf "$MVLC_DIR/$item"
        cp -R "$NESTED_FRAMEWORK/$item" "$MVLC_DIR/$item"
      fi
    done
  fi

  FOUND_BINARY="$(find "$TMP_MVLC" -type f -path '*/MobileVLCKit.framework/MobileVLCKit' -print -quit || true)"
  if [ -z "$FOUND_BINARY" ]; then
    FOUND_BINARY="$(find "$TMP_MVLC" -type f -name 'MobileVLCKit' -print -quit || true)"
  fi

  if [ -z "$FOUND_BINARY" ]; then
    echo "ERROR: MobileVLCKit binary was not found after extraction."
    exit 1
  fi

  echo "Found binary: $FOUND_BINARY"
  cp "$FOUND_BINARY" "$MVLC_BINARY"
  chmod +x "$MVLC_BINARY"
fi

if [ ! -f "$MVLC_BINARY" ]; then
  echo "ERROR: MobileVLCKit framework binary still missing."
  exit 1
fi

echo
echo "== MobileVLCKit binary information =="
file "$MVLC_BINARY"
lipo -info "$MVLC_BINARY" || true

if ! lipo -info "$MVLC_BINARY" 2>/dev/null | grep -q 'arm64'; then
  echo "ERROR: MobileVLCKit does not contain arm64."
  exit 1
fi

echo "MobileVLCKit contains arm64."

echo
echo "== C++ runtime =="
STDCPP_FLAG="-lc++"
echo "Using $STDCPP_FLAG"

echo
echo "== Linking =="

"$CLANG"   -std=c++11   -arch arm64   -isysroot "$SDK"   "iXpand Drive.a"   -dead_strip   -ObjC   -Llib   -Fframeworks   -l"AFNetworking"   -l"BlocksKit"   -l"Bolts"   -l"CSStickyHeaderFlowLayout"   -l"CocoaAsyncSocket"   -l"CocoaHTTPServer"   -l"CocoaLumberjack"   -l"DFCache"   -l"FBSDKCoreKit"   -l"FBSDKLoginKit"   -l"FXKeychain"   -l"GGLCore"   -l"GGLSignIn"   -l"GIPNSURL+FIFE_external"   -l"GSDK_Overload_external"   -l"GTMOAuth2_external_external"   -l"GTMOAuth2_internal_external"   -l"GTMSessionFetcher_core_external"   -l"GTMSessionFetcher_full_external"   -l"GTMStackTrace_external"   -l"GTM_AddressBook_external"   -l"GTM_DebugUtils_external"   -l"GTM_GTMURLBuilder_external"   -l"GTM_KVO_external"   -l"GTM_NSData+zlib"   -l"GTM_NSDictionary+URLArguments_external"   -l"GTM_NSScannerJSON_external"   -l"GTM_NSStringHTML_external"   -l"GTM_NSStringXML_external"   -l"GTM_Regex_external"   -l"GTM_RoundedRectPath_external"   -l"GTM_StringEncoding_external"   -l"GTM_SystemVersion_external"   -l"GTM_UIFont+LineHeight_external"   -l"GTM_core_external"   -l"GTM_iPhone_external"   -l"InstagramKit"   -l"LocalyticsAMP_x64"   -l"NSLogger"   -l"NSLogger-CocoaLumberjack-connector"   -l"OpenInChrome_external"   -l"ProtocolBuffers_external"   -l"RFQuiltLayout"   -l"RHAddressBook"   -l"Reachability"   -l"SSZipArchive"   -l"SVWebViewController"   -l"SignIn_external"   -l"UICKeyChainStore"   -l"apptentive-ios"   -l"bz2"   -l"c++"   -l"iconv"   -l"sqlite3"   $STDCPP_FLAG   -l"xml2"   -l"z"   -framework "AVFoundation"   -framework "AddressBook"   -framework "AddressBookUI"   -framework "AssetsLibrary"   -framework "AudioToolbox"   -framework "CFNetwork"   -framework "CoreData"   -framework "CoreFoundation"   -framework "CoreGraphics"   -framework "CoreLocation"   -framework "CoreMotion"   -framework "CoreText"   -framework "Crashlytics"   -framework "Fabric"   -framework "Foundation"   -framework "HockeySDK"   -framework "ImageIO"   -framework "MessageUI"   -framework "MobileCoreServices"   -framework "MobileVLCKit"   -framework "OpenGLES"   -framework "QuartzCore"   -framework "QuickLook"   -framework "SafariServices"   -framework "Security"   -framework "SystemConfiguration"   -framework "UIKit"   -weak_framework "Accounts"   -weak_framework "AdSupport"   -weak_framework "AudioToolbox"   -weak_framework "CoreGraphics"   -weak_framework "CoreLocation"   -weak_framework "CoreTelephony"   -weak_framework "Foundation"   -weak_framework "QuartzCore"   -weak_framework "Security"   -weak_framework "Social"   -weak_framework "StoreKit"   -weak_framework "UIKit"   -framework "CoreData"   -framework "ExternalAccessory"   -framework "MediaPlayer"   -fobjc-link-runtime   -miphoneos-version-min=12.0   -o "$RESULT_DIR/iXpand Drive"

echo
echo "== Linked executable =="
file "$RESULT_DIR/iXpand Drive"
lipo -info "$RESULT_DIR/iXpand Drive" || true

echo
echo "== Packaging unsigned IPA =="

rm -rf Payload
mkdir Payload
cp -R "$RESULT_DIR" Payload/

rm -f iXpand-unsigned.ipa
zip -qr iXpand-unsigned.ipa Payload

echo
echo "BUILD SUCCESSFUL"
echo "Created: iXpand-unsigned.ipa"
