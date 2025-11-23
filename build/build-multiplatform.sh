#!/bin/bash
#
# Copyright (c) 2025 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation


set -e

# Default values
IMAGE_NAME="${1:-che-server}"
IMAGE_TAG="${2:-latest}"
DOCKERFILE="${3:-build/dockerfiles/Dockerfile}"

echo "Building multiplatform image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Using Dockerfile: ${DOCKERFILE}"
echo "Platforms: linux/amd64, linux/arm64"
echo ""

# Build the Docker image from the parent directory
cd "$(dirname "$0")/.." || exit 1

# Ensure buildx builder exists
if ! docker buildx inspect multiplatform-builder &> /dev/null; then
  echo "Creating buildx builder 'multiplatform-builder'..."
  docker buildx create --name multiplatform-builder --use
  docker buildx inspect --bootstrap
fi

echo "Building and pushing multiplatform image..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f "${DOCKERFILE}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  --push \
  .

echo ""
echo "✅ Multiplatform build complete: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "   Platforms: linux/amd64, linux/arm64"
echo "   Image has been pushed to registry"
