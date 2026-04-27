#!/usr/bin/env bash
#
# Deploy the BowlsKnockout support site to GitHub Pages.
#
# What this does (in order):
#   1. Checks that the GitHub CLI (`gh`) is installed and authenticated.
#   2. Initialises this folder as a git repository (if it isn't already).
#   3. Commits any changes to index.html / assets.
#   4. Creates a public GitHub repo "bowlsknockout-support" (or reuses it if it
#      already exists) and pushes the contents.
#   5. Enables GitHub Pages on the main branch, root path.
#   6. Prints the public URL — paste this into the "Support URL" field in
#      App Store Connect.
#
# Re-running is safe: it just pushes any new changes and re-points Pages.
#
# Usage:
#   chmod +x deploy.sh   # one time
#   ./deploy.sh

set -euo pipefail

REPO_NAME="bowlsknockout-support"
BRANCH="main"
SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SITE_DIR"

# --- 1. Tooling checks ------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Install it with:  brew install gh"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "You're not signed in to GitHub. Run:  gh auth login"
    exit 1
fi

GH_USER="$(gh api user --jq .login)"

# --- 2. Local git repo ------------------------------------------------------
if [ ! -d .git ]; then
    echo "Initialising local git repo..."
    git init -b "$BRANCH" >/dev/null
fi

# --- 3. Commit any changes --------------------------------------------------
git add -A
if ! git diff --cached --quiet; then
    git commit -m "Update support site" >/dev/null
    echo "Committed local changes."
else
    echo "No local changes to commit."
fi

# --- 4. Create or push to the remote repo -----------------------------------
if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
    echo "Remote repo $GH_USER/$REPO_NAME already exists. Pushing..."
    if ! git remote get-url origin >/dev/null 2>&1; then
        git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
    fi
    git branch -M "$BRANCH"
    git push -u origin "$BRANCH"
else
    echo "Creating remote repo $GH_USER/$REPO_NAME..."
    gh repo create "$REPO_NAME" \
        --public \
        --description "Support page for BowlsKnockout" \
        --source=. \
        --remote=origin \
        --push
fi

# --- 5. Enable GitHub Pages (idempotent) ------------------------------------
echo "Configuring GitHub Pages..."
gh api -X POST "repos/$GH_USER/$REPO_NAME/pages" \
    -f "source[branch]=$BRANCH" \
    -f "source[path]=/" \
    --silent 2>/dev/null || true

# --- 6. Output the public URLs ---------------------------------------------
BASE_URL="https://$GH_USER.github.io/$REPO_NAME"
SUPPORT_URL="$BASE_URL/"
PRIVACY_URL="$BASE_URL/privacy.html"

echo ""
echo "Done."
echo ""
echo "Support URL (paste into App Store Connect → Support URL):"
echo "    $SUPPORT_URL"
echo ""
echo "Privacy Policy URL (paste into App Store Connect → Privacy Policy URL):"
echo "    $PRIVACY_URL"
echo ""
echo "First-time deploys typically go live within 30 to 60 seconds."
