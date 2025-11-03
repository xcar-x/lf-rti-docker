#!/bin/bash

# SPDX-FileCopyrightText: (c) 2024 Xronos Inc.
# SPDX-License-Identifier: BSD-3-Clause

set -e

git_ref=${1:-4f183a4}
echo using reactor-c git commit ref ${git_ref}
if [ -n "${1}" ]; then shift; fi

docker buildx build . \
    --build-arg RTI_USE_SSL=OFF \
    --build-arg RTI_GIT_REF=${git_ref} \
    --platform=linux/aarch64 \
    --tag=soafee-cr-repo-registry-vpc.ap-southeast-1.cr.aliyuncs.com/soafee-w3/soafee-w3-avp:reactor-c-${git_ref} \
    --push \
    "$@"
