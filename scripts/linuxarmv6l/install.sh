#!/bin/bash
# set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR
APOTHECARY_LEVEL="$( cd "$SCRIPT_DIR/../.." && pwd )"


sudo apt-get install -y aptitude build-essential gawk gcc g++ gfortran git texinfo bison libncurses-dev cmake unzip pkg-config flex openssl pigz autoconf automake tar figlet xz-utils
sudo aptitude install -y gperf
