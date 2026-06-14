# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: signin.spec.js >> SignIn Component >> AC4: wrong password shows error message
- Location: .codevalid/ui/tests/signin.spec.js:84:3

# Error details

```
TimeoutError: browserType.launch: Timeout 180000ms exceeded.
Call log:
  - <launching> /var/folders/dh/7nj_3cjd0h9bny4hgh2gfv_w0000gn/T/cursor-sandbox-cache/5b090cbac18aa538f0669c30bfc5e36d/playwright/chromium_headless_shell-1223/chrome-headless-shell-mac-x64/chrome-headless-shell --disable-field-trial-config --disable-background-networking --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-back-forward-cache --disable-breakpad --disable-client-side-phishing-detection --disable-component-extensions-with-background-pages --disable-component-update --no-default-browser-check --disable-default-apps --disable-dev-shm-usage --disable-edgeupdater --disable-extensions --disable-features=AvoidUnnecessaryBeforeUnloadCheckSync,BoundaryEventDispatchTracksNodeRemoval,DestroyProfileOnBrowserClose,DialMediaRouteProvider,GlobalMediaControls,HttpsUpgrades,LensOverlay,MediaRouter,PaintHolding,ThirdPartyStoragePartitioning,Translate,AutoDeElevate,RenderDocument,OptimizationHints,msForceBrowserSignIn,msEdgeUpdateLaunchServicesPreferredVersion --enable-features=CDPScreenshotNewSurface --allow-pre-commit-input --disable-hang-monitor --disable-ipc-flooding-protection --disable-popup-blocking --disable-prompt-on-repost --disable-renderer-backgrounding --force-color-profile=srgb --metrics-recording-only --no-first-run --password-store=basic --use-mock-keychain --no-service-autorun --export-tagged-pdf --disable-search-engine-choice-screen --unsafely-disable-devtools-self-xss-warnings --edge-skip-compat-layer-relaunch --disable-infobars --disable-search-engine-choice-screen --disable-sync --enable-unsafe-swiftshader --headless --hide-scrollbars --mute-audio --blink-settings=primaryHoverType=2,availableHoverTypes=2,primaryPointerType=4,availablePointerTypes=4 --no-sandbox --user-data-dir=/var/folders/dh/7nj_3cjd0h9bny4hgh2gfv_w0000gn/T/playwright_chromiumdev_profile-WMcx3c --remote-debugging-pipe --no-startup-window
  - <launched> pid=49964
  - [pid=49964][err] Received signal 11 SEGV_MAPERR 000000000010
  - [pid=49964][err]  [0x000109f08073]
  - [pid=49964][err]  [0x000109f0ba33]
  - [pid=49964][err]  [0x7ff8176f331d]
  - [pid=49964][err]  [0x00000000010b]
  - [pid=49964][err]  [0x000106a96475]
  - [pid=49964][err]  [0x0001076ce20a]
  - [pid=49964][err]  [0x000106669436]
  - [pid=49964][err]  [0x000107dfebb2]
  - [pid=49964][err]  [0x000107dffbdc]
  - [pid=49964][err]  [0x00020ecd0530]
  - [pid=49964][err] [end of stack trace]

```