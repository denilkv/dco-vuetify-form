#!/bin/bash
# npm version patch
# Usage:
# - set environment variable NPM_TOKEN to an npm automation token (with 2FA bypass)
# - run this script to publish non-interactively

if [ -z "$NPM_TOKEN" ]; then
	echo "NPM_TOKEN not set — publishing will be interactive (may require OTP)."
	echo "Run: export NPM_TOKEN=\"<your-token>\" && ./publish-npm.sh"
	npm publish
	exit $?
fi

# Write temporary npm auth file for this session (removed after publish)
echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc
chmod 600 ~/.npmrc

npm publish
rc=$?

# Clean up
rm -f ~/.npmrc
exit $rc