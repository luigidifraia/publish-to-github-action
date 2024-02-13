#!/bin/sh

# Check values
if [ -z "${TIMESTAMP}" ]; then
   TIMESTAMP=$(date -u +"%H:%M:%S %d/%m/%Y %A")
else
   # Validate TIMESTAMP format
   if ! date -d "${TIMESTAMP}" >/dev/null 2>&1; then
       echo "error: invalid TIMESTAMP format. Please provide the timestamp in correct format (HH:MM:SS dd/MM/YYYY Day)."
       exit 1
   fi
fi

if [ -z "${GITHUB_TOKEN}" ]; then
   echo "error: GITHUB_TOKEN is not provided"
   exit 1
fi

if [ -n "$SSL_VERIFY" ] && [ "$SSL_VERIFY" = "true" ]; then
    SSL_VERIFY=true
else
    SSL_VERIFY=false
fi

if [ -z "${NAME}" ]; then
   export NAME="Automated Publisher"
fi

if [ -z "${EMAIL}" ]; then
   export EMAIL="actions@users.noreply.github.com"
fi

if [ -z "${BRANCH_NAME}" ]; then
   export BRANCH_NAME="main"
fi

if [ -z "${COMMIT_MESSAGE}" ]; then
   export COMMIT_MESSAGE="Automated publish: ${TIMESTAMP} ${GITHUB_SHA}"
fi

if [ -n "$ONLY_TRACKED" ] && [ "$ONLY_TRACKED" = "true" ]; then
    ONLY_TRACKED="."
else
    ONLY_TRACKED=""
fi

if [ -n "$NO_VERIFY" ] && [ "$NO_VERIFY" = "true" ]; then
    NO_VERIFY="--no-verify"
else
    NO_VERIFY=""
fi

# Initialize git
remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git config http.sslVerify "${SSL_VERIFY}" || { echo "error: Failed to set http.sslVerify in git config"; }
git config user.name "${NAME}" || { echo "error: Failed to set user.name in git config"; }
git config user.email "${EMAIL}" || { echo "error: Failed to set user.email in git config"; }
git remote add publisher "${remote_repo}" || { echo "error: Failed to add remote repository"; }
git show-ref # Useful for debugging
git branch --verbose

# Install LFS hooks
git lfs install || { echo "error: Failed to install LFS hooks"; }

# Publish any new files
git checkout ${BRANCH_NAME} || { echo "error: Failed to checkout branch"; }
git add -A ${ONLY_TRACKED} || { echo "error: Failed to add files to staging"; }
git commit -m "${COMMIT_MESSAGE}" ${NO_VERIFY} || { echo "error: Commit failed"; }
git pull --rebase publisher ${BRANCH_NAME} || { echo "error: Failed to pull changes from remote"; }
git push publisher ${BRANCH_NAME} || { echo "error: Failed to push changes to remote"; }