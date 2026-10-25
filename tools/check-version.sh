#!/bin/bash
# The About screen shows the AppVersion string; the store uses the manifest's
# version attribute. Fails when they differ. Run from anywhere.
cd "$(dirname "$0")/.."
manifest=$(grep -o 'iq:application[^>]* version="[^"]*"' manifest.xml | grep -o 'version="[^"]*"$' | cut -d'"' -f2)
resource=$(grep -o '<string id="AppVersion">[^<]*' resources/strings/strings.xml | cut -d'>' -f2)
if [ -z "$manifest" ] || [ "$manifest" != "$resource" ]; then
	echo "Version mismatch: manifest.xml '$manifest', AppVersion string '$resource'" >&2
	exit 1
fi
echo "Version $manifest"
