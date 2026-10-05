#!/bin/bash

# --- top level conf ---
IMAGE="texlive/texlive:latest"
INPUT_FNAME="main.tex"


# --- path shits ---
SCRIPT_DIR="$(pwd)"
PROJECT_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$SCRIPT_DIR/out"
BUILD_DIR="$OUTPUT_DIR/build"
#SHARED_DIR=
OUTPUT_FNAME="design_doc.pdf"


## --- validate input exists ---
if [ ! -f "$PROJECT_DIR/$INPUT_FNAME" ]; then
    echo "error: input file not found"
    exit 1
fi


## --- prep for build ---
mkdir -p "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"

echo "building project..."


# --- generate *.pdf files from *.eps ---
docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$PROJECT_DIR:/project" \
    -v "$BUILD_DIR:/build" \
    -w /project \
    "$IMAGE" \
    bash -c "find . -name '*.eps' -exec sh -c 'mkdir -p /build/\$(dirname {}) && epstopdf --outfile=/build/\${0%.eps}-eps-converted-to.pdf {}' {} \;"

# --- generate pdf output ---
docker run --rm \
    -u $(id -u):$(id -g) \
    -v "$PROJECT_DIR:/project:ro" \
    -v "$BUILD_DIR:/build" \
    -w /project \
    "$IMAGE" \
    latexmk -f -xelatex -pdf -cd -outdir=/build "$INPUT_FNAME"


# --- move and rename pdf ---
if [ -f "$BUILD_DIR/main.pdf" ]; then
    cp "$BUILD_DIR/main.pdf" "$OUTPUT_DIR/$OUTPUT_FNAME"
    echo "-------------------------"
    echo "success: created $OUTPUT_DIR/$OUTPUT_FNAME"
else
    echo "failure: pdf generation failed"
    exit 1
fi

