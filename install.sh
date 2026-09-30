#!/usr/bin/env bash
# Install what arc needs on Linux, and arc itself.
#   install.sh runtime   ffmpeg, lame, python, torch (CPU), demucs and the htdemucs weights
#   install.sh arc       the latest published arc build, sha256-checked
#   install.sh all       both: a Claude session in the cloud, a CI job
# The runtime changes rarely and is ~1 GB; arc changes nightly and is ~10 MB,
# which is why they are separate steps (and separate image layers).
set -euo pipefail

PREFIX="${ARC_RUNTIME_PREFIX:-/opt/arc-runtime}"   # venv, torch and HF caches
ARC_HOME="${ARC_HOME:-/opt/arc}"                   # arc, arc-plughost, arc-separate
BASE="https://www.impulsearc.com/arc-cli"

# The separator as it runs on the Macs (~/.arc/separator/venv), torch from the
# CPU index: the CUDA wheels are 2.5 GB and nothing here has a GPU.
TORCH="torch==2.13.0"
TORCHAUDIO="torchaudio==2.11.0"
PACKAGES=(demucs==4.1.0 soundfile==0.14.0 numpy scipy)
MODEL=htdemucs

SUDO=""
[[ $(id -u) -ne 0 ]] && SUDO="sudo"

runtime() {
    $SUDO apt-get update -qq
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends \
        ffmpeg libmp3lame0 ca-certificates curl python3 python3-venv sqlite3 >/dev/null
    $SUDO mkdir -p "$PREFIX"
    $SUDO chown "$(id -u):$(id -g)" "$PREFIX"
    python3 -m venv "$PREFIX/venv"
    "$PREFIX/venv/bin/pip" install -q --no-cache-dir --index-url https://download.pytorch.org/whl/cpu "$TORCH" "$TORCHAUDIO"
    "$PREFIX/venv/bin/pip" install -q --no-cache-dir "${PACKAGES[@]}"
    # The weights, now: a separation should not wait on a download, or fail
    # with no network.
    HF_HOME="$PREFIX/hf" TORCH_HOME="$PREFIX/torch" \
        "$PREFIX/venv/bin/python" -c "from demucs.pretrained import get_model; get_model('$MODEL')"
    echo "arc-runtime: $("$PREFIX/venv/bin/python" -c 'import torch, demucs; print("torch", torch.__version__, "demucs", demucs.__version__)')"
}

arc() {
    local build commit date file sum
    read -r build commit date file sum < <(curl -fsSL "$BASE/latest-linux-x86_64.txt")
    curl -fsSL -o /tmp/arc.tar.gz "$BASE/$file"
    echo "$sum  /tmp/arc.tar.gz" | sha256sum -c - >/dev/null
    $SUDO mkdir -p "$ARC_HOME/lib"
    $SUDO tar xzf /tmp/arc.tar.gz -C "$ARC_HOME"
    rm /tmp/arc.tar.gz
    # The binary asks for liblame.so, which no distribution names that way
    # (bkazez/arc#852); Debian's libmp3lame is the same library.
    $SUDO ln -sf "$(ldconfig -p | awk '/libmp3lame.so.0 /{print $NF; exit}')" "$ARC_HOME/lib/liblame.so"
    $SUDO ln -sf "$ARC_HOME/arc" /usr/local/bin/arc
    echo "arc: build $build ($commit, $date)"
}

env_lines() {   # what a shell, a Dockerfile or a setup script must export
    cat <<ENV
export ARC_SEPARATOR_PYTHON=$PREFIX/venv/bin/python
export HF_HOME=$PREFIX/hf
export TORCH_HOME=$PREFIX/torch
export LD_LIBRARY_PATH=$ARC_HOME/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}
ENV
}

case "${1:-all}" in
    runtime) runtime ;;
    arc) arc ;;
    all) runtime; arc; env_lines | $SUDO tee /etc/profile.d/arc.sh >/dev/null
         echo "arc-runtime: environment in /etc/profile.d/arc.sh" ;;
    env) env_lines ;;
    *) echo "usage: install.sh [runtime|arc|all|env]" >&2; exit 1 ;;
esac
