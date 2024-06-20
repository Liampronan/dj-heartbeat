#!/bin/sh

echo "Stage: PRE-Xcode Build is activated .... "

# Move to the place where the scripts are located.
# This is important because the position of the subsequently mentioned files depend of this origin.
#cd $CI_WORKSPACE/ci_scripts || exit 1

# Write a JSON File containing all the environment variables and secrets.
printf "{\"spotifyClientId\":\"%s\",\"spotifyRedirectURL\":\"%s\", \"apiBaseURL\":\"%s\"}" "$SPOTIFY_CLIENT_ID" "$SPOTIFY_REDIRECT_URL" "$API_BASE_URL" >> ../dj-heartbeat/config.json

echo "Wrote config.json file."

echo "Decoding GoogleService-Info.plist from environment variable..."
echo "$FIREBASE_GOOGLESERVICE_INFO_PLIST_BASE64" | base64 --decode > ../dj-heartbeat/GoogleService-Info.plist

echo "Stage: PRE-Xcode Build is DONE .... "

exit 0
