#!/usr/bin/env bash
# PreToolUse guard for Bash: blocks any shell command that names a signing secret, so Claude
# cannot cat, copy, grep or keytool its way to the upload key (docs/RELEASE.md).
# The Read/Edit deny rules in .claude/settings.json cover the file tools; this covers the shell.
input=$(cat)
if printf '%s' "$input" | grep -Eiq 'key\.properties([^.]|$)|\.jks|\.keystore|\.p12|\.pk8|\.pepk|android-keys|storePassword|keyPassword|keytool'; then
  echo "Blocked by .claude/hooks/guard-secrets.sh: this command touches release signing secrets. The owner runs it by hand (docs/RELEASE.md)." >&2
  exit 2
fi
exit 0
