#!/bin/bash
# Archives main and uploads it to TestFlight.
#
# The build number is main's commit count, so every upload is higher than the last;
# the script refuses anything but a full, clean checkout of main as it is on GitHub.
# Signing is automatic for the team in project.yml, through the Apple account Xcode
# is signed in to. The archive is kept in Xcode's Archives folder, so the Organizer
# can symbolicate TestFlight crashes and re-export a failed upload.
set -euo pipefail

repository_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repository_root"

refuse() {
    echo "$1" >&2
    exit 1
}

[ "$(git rev-parse --is-shallow-repository)" = false ] ||
    refuse "This is a shallow clone, so the commit count is wrong."
[ "$(git symbolic-ref --short HEAD)" = main ] ||
    refuse "Upload from main only, so build numbers only rise."
[ -z "$(git status --porcelain)" ] ||
    refuse "The checkout has changes or untracked files; upload a committed state only."
git fetch --quiet origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] ||
    refuse "Local main differs from origin/main; pull or push first."

build_number=$(git rev-list --count HEAD)
archive_path="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/Clankers $build_number.xcarchive"
mkdir -p "$(dirname "$archive_path")"
export_directory=$(mktemp -d)
trap 'rm -rf "$export_directory"' EXIT

echo "Uploading $(git rev-parse --short HEAD) as build $build_number"
xcodegen generate
xcodebuild -project Clankers.xcodeproj -scheme Clankers -configuration Release \
    -destination 'generic/platform=iOS' -archivePath "$archive_path" \
    -allowProvisioningUpdates CURRENT_PROJECT_VERSION="$build_number" archive
xcodebuild -exportArchive -archivePath "$archive_path" \
    -exportOptionsPlist tools/ExportOptions.plist \
    -exportPath "$export_directory" -allowProvisioningUpdates
