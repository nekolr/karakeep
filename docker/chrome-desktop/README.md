# Karakeep Desktop Chrome

This image runs full Google Chrome inside Xvfb with Openbox, exposes the
DevTools endpoint on port 9222, and optionally serves the desktop through
noVNC on port 6080. It is intended for environments where a visible desktop
browser passes bot-protection checks more reliably than headless Chrome.

The image targets `linux/amd64` because Google does not publish Linux Chrome
builds for other architectures.

## Build and run

From `docker/`:

```sh
docker compose build chrome
docker compose up -d chrome
```

Open `http://127.0.0.1:6080/vnc.html` for the desktop. Both the noVNC and
DevTools ports bind to localhost by default.

## Chrome version

`GOOGLE_CHROME_VERSION` pins the Google Chrome package installed by the image.
The default follows Karakeep's tested Chrome version. Rebuild the image after
changing it:

```sh
GOOGLE_CHROME_VERSION=157.0.8103.38 docker compose build --no-cache chrome
```

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `GOOGLE_CHROME_VERSION` | `157.0.8103.38` | Google Chrome package version. |
| `UBUNTU_IMAGE` | `ubuntu:24.04` | Ubuntu base image, useful with a registry mirror. |
| `CHROME_DOWNLOAD_URL` | Google package URL | Override the Chrome `.deb` download URL, for example a local cache. |
| `CHROME_DOWNLOAD_PROXY` | empty | Proxy used only to download the Chrome package during the build. |
| `UBUNTU_APT_MIRROR` | Aliyun mirror | Ubuntu package mirror used during the build. |
| `KARAKEEP_CHROME_DESKTOP_PORT` | `127.0.0.1:6080:6080` | Host binding for noVNC. |
| `KARAKEEP_CHROME_DEBUG_PORT` | `127.0.0.1:9222:9222` | Host binding for the DevTools endpoint. |
| `CHROME_PROXY_SERVER` | empty | Chrome-level proxy for all browser traffic. |
| `CHROME_PROXY_BYPASS_LIST` | empty | Semicolon-separated Chrome proxy bypass list. |
| `CHROME_EXTRA_ARGS` | empty | Additional Chrome command-line arguments. |
| `CHROME_DISABLE_SANDBOX` | `false` | Passes `--no-sandbox`; use only when sandbox startup fails. |
| `CRAWLER_CHALLENGE_WAIT_SEC` | `15` | Time allowed for self-clearing bot challenges. |
| `CRAWLER_BROWSER_TIMEZONE` | host/browser default | IANA timezone matching the proxy exit location. |

`CRAWLER_HTTP_PROXY` and `CRAWLER_HTTPS_PROXY` configure the worker's fetches
and browser contexts. When `CHROME_PROXY_SERVER` is also set, use the same exit
so manual browsing and automated crawls do not present conflicting network
identities.

The container currently requests `SYS_ADMIN` so Chrome's sandbox can start
under Docker's default seccomp policy. Keep the noVNC and DevTools ports bound
to localhost unless remote access is protected separately.
