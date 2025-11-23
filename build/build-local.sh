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

echo "Building ${IMAGE_NAME}:${IMAGE_TAG} (local only, no push)"
echo "Using Dockerfile: build/dockerfiles/Dockerfile"
echo ""

# Build the Docker image for local use (no multiplatform)
docker build \
  -f build/dockerfiles/Dockerfile \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  .

echo ""
echo "✅ Local build complete: ${IMAGE_NAME}:${IMAGE_TAG}"

