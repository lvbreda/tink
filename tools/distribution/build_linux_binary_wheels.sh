#!/bin/bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################


# This script builds binary wheels of Tink for Linux based on PEP 599. It
# should be run inside a manylinux2014 Docker container to have the correct
# environment setup.

set -euo pipefail

# The following assoicative array contains:
#   ["<Python version>"]="<python tag>-<abi tag>"
# where:
#   <Python version> = language version, e.g "3.7"
#   <python tag>, <abi tag> = as defined at
#       https://packaging.python.org/en/latest/specifications/, e.g. "cp37-37m"
declare -A PYTHON_VERSIONS
PYTHON_VERSIONS["3.7"]="cp37-cp37m"
PYTHON_VERSIONS["3.8"]="cp38-cp38"
PYTHON_VERSIONS["3.9"]="cp39-cp39"
PYTHON_VERSIONS["3.10"]="cp310-cp310"
readonly -A PYTHON_VERSIONS

export TINK_PYTHON_ROOT_PATH="${PWD}"

readonly BAZEL_VERSION="$(cat ${TINK_PYTHON_ROOT_PATH}/.bazelversion)"
# Contains python version 4.21.9 of protobuf
readonly PROTOC_RELEASE_TAG="21.9"

# Get dependencies which are needed for building Tink.

# Install Bazel. Needed for building C++ extensions.
curl -OL "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
chmod +x "bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
./"bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"

# Install protoc. Needed for protocol buffer compilation.
PROTOC_ZIP="protoc-${PROTOC_RELEASE_TAG}-linux-x86_64.zip"
curl -OL "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_RELEASE_TAG}/${PROTOC_ZIP}"
unzip -o "${PROTOC_ZIP}" -d /usr/local bin/protoc

# Required to fix https://github.com/pypa/manylinux/issues/357.
export LD_LIBRARY_PATH="/usr/local/lib"

for v in "${!PYTHON_VERSIONS[@]}"; do
  (
    # Executing in a subshell to make the PATH modification temporary.
    # This makes shure that `which python3 ==
    # /opt/python/${PYTHON_VERSIONS[$v]}/bin/python3`, which is a symlink of
    # `/opt/python/${PYTHON_VERSIONS[$v]}/bin/python${v}`. This should allow
    # pybind11_bazel to pick up the correct Python binary [1].
    #
    # [1] https://github.com/pybind/pybind11_bazel/blob/fc56ce8a8b51e3dd941139d329b63ccfea1d304b/python_configure.bzl#L434
    export PATH="${PATH}:/opt/python/${PYTHON_VERSIONS[$v]}/bin"
    pip wheel .
  )

  # This is needed to ensure we get a clean build, otherwise parts of the
  # compiled code from a previous build may be reused in a subsequent build.
  bazel clean --expunge
done

# Repair wheels to convert them from linux to manylinux.
for wheel in ./tink*.whl; do
    auditwheel repair "${wheel}" -w release
done
