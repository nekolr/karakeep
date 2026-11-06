ARG UBUNTU_IMAGE=ubuntu:24.04
FROM ${UBUNTU_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/chrome

ARG UBUNTU_APT_MIRROR=http://mirrors.aliyun.com/ubuntu/
ARG GOOGLE_CHROME_VERSION=157.0.8103.38
ARG CHROME_DOWNLOAD_URL=
ARG CHROME_DOWNLOAD_PROXY=

RUN test "$(dpkg --print-architecture)" = "amd64" \
    && sed -i "s|http://archive.ubuntu.com/ubuntu/|${UBUNTU_APT_MIRROR}|g; s|http://security.ubuntu.com/ubuntu/|${UBUNTU_APT_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus-x11 \
        fonts-liberation \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        novnc \
        openbox \
        python3 \
        python3-websockify \
        socat \
        x11vnc \
        xvfb

RUN CHROME_URL="${CHROME_DOWNLOAD_URL:-https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${GOOGLE_CHROME_VERSION}-1_amd64.deb}" \
    && HTTPS_PROXY="${CHROME_DOWNLOAD_PROXY}" https_proxy="${CHROME_DOWNLOAD_PROXY}" curl -fsSL -o /tmp/google-chrome.deb "${CHROME_URL}" \
    && apt-get install -y --no-install-recommends /tmp/google-chrome.deb \
    && rm -f /tmp/google-chrome.deb \
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
