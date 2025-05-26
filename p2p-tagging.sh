#!/bin/bash

# Check if a version argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1.1.7"
    exit 1
fi

VERSION=$1

# Validate version format
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format v*.*.*"
    echo "Example: v1.1.7"
    exit 1
fi

# Delete existing branch if it exists
BRANCH_NAME="release-$VERSION"
if git show-ref --quiet refs/heads/$BRANCH_NAME; then
    echo "Branch $BRANCH_NAME exists, deleting..."
    git branch -D $BRANCH_NAME
fi

# Create new branch from the version tag
echo "Creating new branch from $VERSION..."
git checkout -b $BRANCH_NAME $VERSION

# Copy the workflow file from main
echo "Copying workflow file from main..."
git checkout main -- .github/workflows/build-images.yml
git add .github/workflows/build-images.yml
git commit -m "Add build-images workflow for p2p tag"

# Create new p2p tag
P2P_TAG="${VERSION}-p2p"
echo "Creating new tag $P2P_TAG..."

# Delete local tag if it exists
if git rev-parse "$P2P_TAG" >/dev/null 2>&1; then
    echo "Local tag $P2P_TAG exists, deleting..."
    git tag -d $P2P_TAG
fi

# Delete remote tag if it exists
if git ls-remote --tags origin "refs/tags/$P2P_TAG" | grep -q "$P2P_TAG"; then
    echo "Remote tag $P2P_TAG exists, deleting..."
    git push --delete origin $P2P_TAG || true
fi

# Create and push new tag
git tag $P2P_TAG
echo "Pushing tag to origin..."
if git push -f origin $P2P_TAG; then
    echo "Successfully created and pushed $P2P_TAG"
    echo "The CI workflow will now build images with the $P2P_TAG tag"
else
    echo "Error: Failed to push tag"
    exit 1
fi

# Return to original branch
git checkout main
