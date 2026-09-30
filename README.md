# arc-runtime

Everything [arc](https://www.impulsearc.com/arc-cli/) needs on Linux except arc
itself: ffmpeg, lame, and the voice separator's python with torch (CPU),
demucs and the htdemucs weights. arc goes on top, so a new arc build is a
10 MB layer and never a rebuild of this one.

In a Dockerfile (this is how [continuo.fm](https://continuo.fm) runs Improve
audio):

```dockerfile
FROM ghcr.io/bkazez/arc-runtime:latest
# Re-fetched on every build; the layer below is rebuilt only when a new arc is published.
ADD https://www.impulsearc.com/arc-cli/latest-linux-x86_64.txt /opt/arc/build.txt
RUN /usr/local/share/arc-runtime/install.sh arc /opt/arc/build.txt
```

On a Linux machine or a Claude Code cloud environment's setup script:

```bash
curl -fsSL https://raw.githubusercontent.com/bkazez/arc-runtime/main/install.sh | bash -s all
. /etc/profile.d/arc.sh
arc version
```

What a published image can do is what [`smoke.sh`](smoke.sh) checks before
[the workflow](.github/workflows/image.yml) pushes it.

Not included, because they are licensed or macOS only: commercial plugins
(Altiverb, Seventh Heaven, EQuilibrium, Limitless, Weiss) and the Altiverb
impulse responses behind arc's room library.
