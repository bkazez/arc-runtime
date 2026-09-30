# Everything arc needs on Linux except arc: ffmpeg, lame, and the separator's
# python with torch (CPU), demucs and the htdemucs weights. Rebuilt only when
# this file or install.sh changes. arc itself is ~10 MB and goes on top, in
# whatever image uses this one:
#
#   FROM ghcr.io/bkazez/arc-runtime:latest
#   ADD https://www.impulsearc.com/arc-cli/latest-linux-x86_64.txt /opt/arc/build.txt
#   RUN /usr/local/share/arc-runtime/install.sh arc /opt/arc/build.txt
FROM debian:trixie-slim
COPY install.sh /usr/local/share/arc-runtime/install.sh
RUN /usr/local/share/arc-runtime/install.sh runtime && rm -rf /var/lib/apt/lists/*
ENV ARC_SEPARATOR_PYTHON=/opt/arc-runtime/venv/bin/python \
    HF_HOME=/opt/arc-runtime/hf \
    TORCH_HOME=/opt/arc-runtime/torch \
    HF_HUB_OFFLINE=1 \
    LD_LIBRARY_PATH=/opt/arc/lib
LABEL org.opencontainers.image.source=https://github.com/bkazez/arc-runtime
