#!/usr/bin/env bash
set -euo pipefail

APP="app/iXpand Drive.app"
OUT="iXpand-unsigned.ipa"

echo "== Xcode =="
XCODE_BASE="$(xcode-select -p | sed 's#/Contents/Developer$##')"
echo "XCODE_BASE=$XCODE_BASE"
xcodebuild -version

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --sdk iphoneos -f clang)"

echo "SDK=$SDK"
echo "CLANG=$CLANG"

if [ ! -x "$CLANG" ]; then
  echo "ERROR: clang was not found."
  exit 2
fi

if [ ! -f "iXpand Drive.a" ]; then
  echo "ERROR: iXpand Drive.a is missing."
  exit 2
fi

if [ ! -d "$APP" ]; then
  echo "ERROR: $APP is missing."
  exit 2
fi

echo "== Inspecting libraries =="

echo "--- Main application library ---"
file "iXpand Drive.a"
xcrun lipo -info "iXpand Drive.a" || true

echo "--- Library directory ---"
find lib -maxdepth 2 -type f | sort | head -200

echo "--- Framework directory ---"
find frameworks -maxdepth 2 -type f | sort | head -200

# Remove anything from the old application bundle that would interfere
# with producing an unsigned IPA.
rm -f "$APP/embedded.mobileprovision"
rm -rf "$APP/_CodeSignature"
rm -f "$APP/iXpand Drive"

# Copy application metadata.
cp Info.plist "$APP/Info.plist"

if [ -f GoogleService-Info.plist ]; then
  cp GoogleService-Info.plist "$APP/GoogleService-Info.plist"
fi

echo
echo "== Checking C++ libraries =="

if [ -f "$SDK/usr/lib/libc++.tbd" ]; then
  echo "Modern libc++ found."
else
  echo "WARNING: libc++ not found."
fi

if [ -f "lib/libstdc++.a" ]; then
  echo "Bundled libstdc++.a found."
  STDCPP_PATH="$PWD/lib/libstdc++.a"
else
  echo "Bundled libstdc++.a NOT found."
  STDCPP_PATH=""
fi

echo
echo "== Linking arm64 =="

LINK_ARGS=(
  -arch arm64
  -isysroot "$SDK"

  "iXpand Drive.a"

  -dead_strip
  -ObjC

  -Llib
  -Fframeworks

  -lAFNetworking
  -lBlocksKit
  -lBolts
  -lCSStickyHeaderFlowLayout
  -lCocoaAsyncSocket
  -lCocoaHTTPServer
  -lCocoaLumberjack
  -lDFCache
  -lFBSDKCoreKit
  -lFBSDKLoginKit
  -lFXKeychain
  -lGGLCore
  -lGGLSignIn

  -lGIPNSURL+FIFE_external
  -lGSDK_Overload_external
  -lGTMOAuth2_external_external
  -lGTMOAuth2_internal_external
  -lGTMSessionFetcher_core_external
  -lGTMSessionFetcher_full_external
  -lGTMStackTrace_external
  -lGTM_AddressBook_external
  -lGTM_DebugUtils_external
  -lGTM_GTMURLBuilder_external
  -lGTM_KVO_external
  -lGTM_NSData+zlib
  -lGTM_NSDictionary+URLArguments_external
  -lGTM_NSScannerJSON_external
  -lGTM_NSStringHTML_external
  -lGTM_NSStringXML_external
  -lGTM_Regex_external
  -lGTM_RoundedRectPath_external
  -lGTM_StringEncoding_external
  -lGTM_SystemVersion_external
  -lGTM_UIFont+LineHeight_external
  -lGTM_core_external
  -lGTM_iPhone_external

  -lInstagramKit
  -lLocalyticsAMP_x64
  -lNSLogger
  -lNSLogger-CocoaLumberjack-connector
  -lOpenInChrome_external
  -lProtocolBuffers_external
  -lRFQuiltLayout
  -lRHAddressBook
  -lReachability
  -lSSZipArchive
  -lSVWebViewController
  -lSignIn_external
  -lUICKeyChainStore
  -lapptentive-ios
  -lbz2
  -liconv
  -lsqlite3
  -lxml2
  -lz

  -framework AVFoundation
  -framework AddressBook
  -framework AddressBookUI
  -framework AssetsLibrary
  -framework AudioToolbox
  -framework CFNetwork
  -framework CoreData
  -framework CoreFoundation
  -framework CoreGraphics
  -framework CoreLocation
  -framework CoreMotion
  -framework CoreText
  -framework Crashlytics
  -framework Fabric
  -framework Foundation
  -framework HockeySDK
  -framework ImageIO
  -framework MessageUI
  -framework MobileCoreServices
  -framework MobileVLCKit
  -framework OpenGLES
  -framework QuartzCore
  -framework QuickLook
  -framework SafariServices
  -framework Security
  -framework SystemConfiguration
  -framework UIKit

  -weak_framework Accounts
  -weak_framework AdSupport
  -weak_framework CoreTelephony
  -weak_framework Social
  -weak_framework StoreKit

  -framework ExternalAccessory
  -framework MediaPlayer

  -fobjc-link-runtime
  -miphoneos-version-min=8.2

  -o "$APP/iXpand Drive"
)

# The old project requested libstdc++.
# Modern Xcode no longer ships Apple's old libstdc++.
# If the repository contains its own copy, use it explicitly.
if [ -n "$STDCPP_PATH" ]; then
  LINK_ARGS+=("$STDCPP_PATH")
else
  echo
  echo "WARNING: No bundled libstdc++.a."
  echo "Using modern libc++ instead."
  LINK_ARGS+=(-lc++)
fi

"$CLANG" "${LINK_ARGS[@]}"

echo
echo "== Verify executable =="

file "$APP/iXpand Drive"
xcrun lipo -info "$APP/iXpand Drive" || true

echo
echo "== Linked frameworks/libraries =="

xcrun otool -L "$APP/iXpand Drive" | sed -n '1,200p' || true

echo
echo "== Prepare IPA =="

rm -rf Payload
mkdir Payload

cp -R "$APP" "Payload/iXpand Drive.app"

rm -f "$OUT"
/usr/bin/zip -qry "$OUT" Payload

echo
echo "========================================"
echo "SUCCESS: $OUT"
echo "This IPA is unsigned."
echo "========================================"
