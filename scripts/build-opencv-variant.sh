#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROFILE="${1:-}"
ACTION="${2:-all}"
TYPE="${TYPE:-linux}"
ARCH="${ARCH:-x86_64}"

usage() {
    echo "Usage: TYPE=linux|vs ARCH=x86_64 $0 opencv-cuda[-ai] [build|package|all]"
}

case "$PROFILE" in
    opencv-cuda)
        EXTRA_DEFINES="${OPENCV_EXTRA_DEFINES:-}"
        ;;
    opencv-cuda-ai)
        EXTRA_DEFINES="-DBUILD_opencv_dnn=ON -DOPENCV_DNN_CUDA=ON ${OPENCV_EXTRA_DEFINES:-}"
        ;;
    *)
        usage
        exit 2
        ;;
esac

if [[ "$TYPE" != "linux" && "$TYPE" != "vs" ]]; then
    echo "Error: $PROFILE supports TYPE=linux or TYPE=vs, got TYPE=$TYPE" >&2
    exit 2
fi
if [[ "$ACTION" != "build" && "$ACTION" != "package" && "$ACTION" != "all" ]]; then
    usage
    exit 2
fi

VARIANT_ROOT="${VARIANT_OUTPUT_FOLDER:-$ROOT/out-modular/$PROFILE/$TYPE/$ARCH}"
VARIANT_BUILD="${VARIANT_BUILD_DIR:-$ROOT/build-variants/$PROFILE/$TYPE/$ARCH}"
ARTIFACT_DIR="${MODULAR_ARTIFACT_DIR:-$ROOT/xout}"
mkdir -p "$VARIANT_ROOT" "$VARIANT_BUILD" "$ARTIFACT_DIR"

if [[ "$ACTION" == "build" || "$ACTION" == "all" ]]; then
    printf 'y\n' | \
        NO_COLOR="${NO_COLOR:-1}" UI_ANIM="${UI_ANIM:-0}" \
        TYPE="$TYPE" ARCH="$ARCH" \
        OUTPUT_FOLDER="$VARIANT_ROOT" BUILD_DIR="$VARIANT_BUILD" \
        OPENCV_CUDA=1 OPENCV_VARIANT="$PROFILE" \
        OPENCV_EXTRA_DEFINES="$EXTRA_DEFINES" \
        "$ROOT/apo" update opencv
fi

if [[ "$ACTION" == "package" || "$ACTION" == "all" ]]; then
    if [[ ! -d "$VARIANT_ROOT/opencv" ]]; then
        echo "Error: missing variant output: $VARIANT_ROOT/opencv" >&2
        exit 1
    fi
    if [[ "$TYPE" == "vs" ]]; then
        ARTIFACT="$ARTIFACT_DIR/oF_${PROFILE}_${TYPE}_${ARCH}.zip"
        (cd "$VARIANT_ROOT" && 7z a -tzip "$ARTIFACT" opencv)
    else
        ARTIFACT="$ARTIFACT_DIR/oF_${PROFILE}_${TYPE}_${ARCH}.tar.bz2"
        tar -C "$VARIANT_ROOT" -cjf "$ARTIFACT" opencv
    fi
    echo "Modular artifact: $ARTIFACT"
fi
