# Merge Script
 
# http://code.hootsuite.com/an-introduction-to-creating-and-distributing-embedded-frameworks-in-ios/

# 1
# Set bash script to exit immediately if any commands fail.
set -e
 
# 2
# Setup some constants for use later on.
FRAMEWORK_NAME="SRPPlayerViewController"
 
# 3
# If remnants from a previous build exist, delete them.
if [ -d "build" ]; then
rm -rf "build"
fi
 
# 4
# Build the framework for device and for simulator (using
# all needed architectures).
xcodebuild -target "${FRAMEWORK_NAME}" -configuration Release -arch arm64 -arch armv7 only_active_arch=no defines_module=yes -sdk iphoneos
xcodebuild -target "${FRAMEWORK_NAME}" -configuration Release -arch i386 -arch x86_64 only_active_arch=no VALID_ARCHS="i386 x86_64" -sdk iphonesimulator

# 5
# Remove .framework file if exists on Desktop from previous run.
if [ -d "${HOME}/Desktop/${FRAMEWORK_NAME}.framework" ]; then
rm -rf "${HOME}/Desktop/${FRAMEWORK_NAME}.framework"
fi
 
# 6
# Copy the device version of framework to Desktop.
cp -r "build/Release-iphoneos/${FRAMEWORK_NAME}.framework" "${HOME}/Desktop/${FRAMEWORK_NAME}.framework"
 
# 7
# Replace the framework executable within the framework with
# a new version created by merging the device and simulator
# frameworks' executables with lipo.
lipo -create -output "${HOME}/Desktop/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "build/Release-iphoneos/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "build/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
  
# 9
# Delete the most recent build.
if [ -d "build" ]; then
rm -rf "build"
fi
