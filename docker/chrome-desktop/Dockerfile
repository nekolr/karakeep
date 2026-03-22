FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/chrome

ARG UBUNTU_APT_MIRROR=http://mirrors.aliyun.com/ubuntu/

RUN sed -i "s|http://archive.ubuntu.com/ubuntu/|${UBUNTU_APT_MIRROR}|g; s|http://security.ubuntu.com/ubuntu/|${UBUNTU_APT_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        dbus-x11 \
        fonts-liberation \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        google-chrome-stable \
        novnc \
        openbox \
        python3 \
        python3-websockify \
        socat \
        x11vnc \
        xvfb \
    && useradd --create-home --shell /bin/bash chrome \
    && mkdir -p /tmp/chrome-profile /tmp/runtime-chrome \
    && chown -R chrome:chrome /home/chrome /tmp/chrome-profile /tmp/runtime-chrome \
    && rm -f /etc/machine-id \
    && dbus-uuidgen --ensure=/etc/machine-id \
    && rm -rf /var/lib/apt/lists/*

COPY start-chrome-desktop.sh /usr/local/bin/start-chrome-desktop.sh

RUN chmod +x /usr/local/bin/start-chrome-desktop.sh

USER chrome

EXPOSE 9222 5900 6080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD curl -fsS http://127.0.0.1:9222/json/version > /dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/start-chrome-desktop.sh"]