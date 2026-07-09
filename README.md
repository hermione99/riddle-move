# riddle — for the reMarkable Paper Pro **Move** (한국어 지원)

> **This is a fork of [MaximeRivest/riddle](https://github.com/MaximeRivest/riddle)**,
> adapted for the smaller **reMarkable Paper Pro Move** (codename *chiappa*,
> 954×1696) and with an optional **native Korean** build (나눔손글씨 펜 폰트 +
> 한국어 페르소나). All credit for the original diary goes to Maxime Rivest.
> Licensed **MIT**, same as upstream.

Write on the page with your pen. After a pause, the diary **drinks your ink**,
thinks for a moment, and answers in a flowing hand — now on the Move, and now
in Korean if you want it.

한 줄 요약: **리마커블 페이퍼 프로 무브**용으로 개조하고, 원하면 **한글 손글씨체 +
자연스러운 한국어**로 답하도록 만든 riddle 포크입니다.

---

## What's different from upstream

The Move has a different panel and digitizer than the big Paper Pro, so the
Move-specific values are baked in:

- **Screen** 954×1696 (was 1620×2160) — `src/fb.rs`
- **qtfb (windowed) format** `FBFMT_RMPPM_RGB565` / 954×1696 — `src/display.rs`, `src/qtfb.rs`
- **Pen digitizer range** 6760×11960 (Move's "Elan marker input") — `src/pen.rs`
- **Reply font size** scaled to the smaller screen — `src/main.rs`
- **qtfb pacing** is env-tunable (windowed mode goes through the compositor, so
  it can't sustain a high refresh rate): `RIDDLE_FLUSH_MS`, `RIDDLE_REPLY_STEP_MS`,
  `RIDDLE_REPLY_BUDGET` in `oracle.env`.
- **Korean build** (`--features korean`): embeds Nanum Pen Script (Hangul+Latin)
  and swaps the persona + UI strings to native Korean.

> ⚠️ These builds target the **Move only**. For the original Paper Pro use upstream.

## Building

Two **independent** switches — any of the four combinations is valid:

- **Language:** English (default), or Korean with `--features korean`
- **Display:** windowed via AppLoad/qtfb (default), or full-takeover with `--features takeover`

| | **Windowed** (AppLoad/qtfb) — static musl, no SDK | **Full-takeover** (instant ink) — needs vendor libs |
|---|---|---|
| **English** | `--target aarch64-unknown-linux-musl` | `--target aarch64-unknown-linux-gnu --features takeover` |
| **Korean** | `--target aarch64-unknown-linux-musl --features korean` | `--target aarch64-unknown-linux-gnu --features "korean takeover"` |

```sh
cd riddle

# English, windowed (static musl — no SDK, no vendor libs):
cargo build --release --target aarch64-unknown-linux-musl

# English, full-takeover (instant ink — needs libquill.so + libqsgepaper.so, see below):
cargo build --release --target aarch64-unknown-linux-gnu --features takeover

# Korean, windowed:
cargo build --release --target aarch64-unknown-linux-musl --features korean

# Korean, full-takeover:
cargo build --release --target aarch64-unknown-linux-gnu --features "korean takeover"
```

**Windowed vs takeover:** windowed builds are the easy path — fully static
(musl), need no SDK and no vendor libraries, and run as a normal AppLoad
window, but ink goes through xochitl's compositor so it can't match takeover's
latency (tune with the `RIDDLE_*` env vars above). Takeover drives the vendor
e-ink engine directly for instant ink, but must link the vendor libraries
described below.

**Cross-compiling takeover without the reMarkable SDK:** the `gnu` targets only
need a macOS/Linux-hosted `aarch64-unknown-linux-gnu` toolchain (e.g. Homebrew's
`messense/macos-cross-toolchains`). Pass `-C link-arg=-Wl,--allow-shlib-undefined`
so the linker doesn't need a full Qt sysroot — the vendor libraries resolve at
runtime on the device. Building against the toolchain's older glibc and running
on the device's newer glibc is fine.

### Vendor libraries (takeover mode only) — not distributed here

Takeover mode links two libraries that are **not in this repo** and must come
from **your own device**:

- `libqsgepaper.so` — reMarkable's proprietary e-ink scenegraph plugin.
  Pull it from your device: `/usr/lib/plugins/scenegraph/libqsgepaper.so`.
- `libquill.so` — build it from the `quill/` project (see upstream), or reuse
  the one shipped in an upstream release bundle.

Place them at `quill/vendor/libqsgepaper.so` and `quill/build/libquill.so`
before building with `--features takeover`. They are `.gitignore`d on purpose.

Windowed (musl) builds need **neither** — that's the easy path.

### Packaging as an AppLoad app

Drop a folder into `/home/root/xovi/exthome/appload/<name>/` containing the
`riddle` binary, `icon.png`, `appload-launch.sh`, `external.manifest.json`, and
your `oracle.env` (API key — **never commit this**). Windowed apps set
`"qtfb": true`; takeover apps ship `libquill.so` alongside and stop xochitl.
See `scripts/` for launch examples.

## Fonts

- English: **Dancing Script** (SIL OFL 1.1) — `fonts/OFL.txt`
- Korean: **Nanum Pen Script** (SIL OFL 1.1) — `fonts/OFL-NanumPenScript.txt`

## License & credits

MIT (see `LICENSE`), inherited from **[MaximeRivest/riddle](https://github.com/MaximeRivest/riddle)**.
Fonts are SIL OFL 1.1 (see `fonts/`). The vendor libraries it interposes
(`libqsgepaper.so`, Qt) are **not** included and must come from your own device.

---

<details>
<summary><b>Original upstream README (reMarkable Paper Pro)</b></summary>

# riddle — the diary of Tom Riddle, for the reMarkable Paper Pro

Write on the page with your pen. After a pause, the diary **drinks your ink** —
your words fade into the paper — the page thinks for a moment, and an answer
writes itself back in a flowing hand, stroke by stroke, then fades away.

No screen glow, no keyboard, no chat UI. Just ink appearing on paper.

_This is the diary from [the demo](https://x.com/MaximeRivest)._

### 🪄 New to this? Start here

You need a **reMarkable Paper Pro** in developer mode with a launcher installed.
If that sounds like a lot, it isn't — **[remagic](https://github.com/maximerivest/remagic)**
walks you through turning on developer mode and sets up everything with one
command. Come back here, drop riddle in, and start writing to Tom.

Already have xovi + AppLoad? **[Download the latest release](https://github.com/MaximeRivest/riddle/releases/latest)** — a ready-to-drop bundle, no compiler needed — or [build from source](#building).

### Install the prebuilt bundle

1. Grab `riddle-appload-aarch64.zip` from the [latest release](https://github.com/MaximeRivest/riddle/releases/latest) and unzip it.
2. Copy the folder to your tablet:
   `scp -O -r riddle root@10.11.99.1:/home/root/xovi/exthome/appload/`
3. Add an API key: `cp oracle.env.example oracle.env` in that folder and put your `RIDDLE_OPENAI_KEY` in it (any OpenAI-compatible key). Or skip it to use [pi](#option-b--pi-the-power-path).
4. In **AppLoad**: tap **Reload**, then **The Diary**. Write, and rest your pen.

> ⚠️ **This modifies your device.** It runs as root, stops the vendor UI
> (in takeover mode), and drives the e-ink engine directly. It has only been
> tested on a **reMarkable Paper Pro** (ferrari, aarch64, OS 3.26–3.27). It may
> not work on other models or OS versions, and you use it entirely at your own
> risk. Not affiliated with reMarkable AS. Keep SSH access working before you
> install anything — that is your escape hatch.

## How it works

```
 pen (raw evdev, full 4096-level pressure, hardware event rate)
   │ strokes
   ▼
 riddle ── idle 2.8s → commit page → PNG ──► oracle (resident LLM process,
   │                                          streams reply sentence-by-sentence)
   ▼ strokes (Dancing Script → skeletonized to single-pixel pen paths)
 display backend
   ├── qtfb        — windowed, inside xochitl (AppLoad app)
   └── quill       — full takeover: xochitl stopped, vendor e-ink engine
                     driven directly for instant ink (lowest latency there is)
```

- **`riddle/`** — the app (Rust). Pen input, ink surface, handwriting
  synthesis (rasterize → Zhang-Suen thinning → stroke tracing → animated
  replay), the oracle process manager, and both display backends.
- **`quill/`** — the takeover display host (C/C++). An
  [epfb-re](https://github.com/asivery)-style QImage-constructor interposition
  shim over the vendor `libqsgepaper.so` waveform engine, exposed as a small
  C ABI (`quill_init` / `quill_buffer` / `quill_swap`) that riddle links
  against with `--features takeover`. Includes `scribble`, a minimal
  pen-to-glass latency demo.

## Gestures

| Do this | And |
|---------|-----|
| Write, then rest the pen | The diary drinks your ink and Tom replies |
| Flip the marker | Erase |
| Draw a large **?** | Summon the built-in guide |
| Tap five fingers at once | Leave the diary |
| Power button | The page turns to *"The diary sleeps."*, then the tablet suspends; press again to wake exactly where you were |

## The oracle (the "spirit" in the diary)

The diary's replies come from a vision LLM that reads your handwriting from the
committed page (sent as an inline PNG). There are **two backends**, chosen at
startup — pick whichever you have:

### Option A — any OpenAI-compatible API (easiest, zero setup)

Set an API key and riddle talks straight to an OpenAI-compatible
`/chat/completions` endpoint. Works with OpenAI, OpenRouter, Groq, a local
server — anything that speaks the format. No extra software on the tablet.

```sh
export RIDDLE_OPENAI_KEY="sk-..."                       # required
export RIDDLE_OPENAI_BASE="https://api.openai.com/v1"   # optional (default)
export RIDDLE_OPENAI_MODEL="gpt-4o-mini"                # optional; must see images
```

Any vision-capable model works. Example with OpenRouter:

```sh
export RIDDLE_OPENAI_KEY="$OPENROUTER_API_KEY"
export RIDDLE_OPENAI_BASE="https://openrouter.ai/api/v1"
export RIDDLE_OPENAI_MODEL="openai/gpt-4o-mini"
```

Verify your setup before launching the diary:

```sh
riddle --oracle-test path/to/handwriting.png   # prints the streamed reply
```

Measured ~0.9–1.1 s to first ink on-device. The HTTPS is built into riddle
(pure-Rust, no extra libraries).

### Option B — pi (the power path)

If you already run [`pi`](https://github.com/badlogic/pi-mono), riddle will use
a resident `pi --mode rpc` process kept warm (Node + your subscription auth
loaded once), so each turn pays only model latency. Used automatically when
`RIDDLE_OPENAI_KEY` is **not** set.

Both stream the reply sentence-by-sentence, so the quill starts writing seconds
before the model finishes. The persona prompt lives in `riddle/src/oracle.rs`.

## Building

Cross-compiled from x86_64. Two flavours:

### Windowed (AppLoad/qtfb) — easiest

Requires [xovi + AppLoad](https://github.com/asivery/rm-appload) on the device.

```sh
cd riddle
cargo build --release --target aarch64-unknown-linux-gnu
```

Install to `/home/root/xovi/exthome/appload/riddle/` with
`external.manifest.json`, `appload-launch.sh`, and the binary.

### Takeover (instant ink) — the one from the demo

Requires the reMarkable SDK toolchain (`~/rm-sdk-3.26`) because the linked
vendor Qt libs need its glibc, **and** `libqsgepaper.so` pulled from *your own
device* (it is proprietary and not distributed here):

```sh
cd quill && ./build.sh          # pulls libqsgepaper.so from the device over ssh,
                                # builds libquill.so + scribble
cd ../riddle && ./build-takeover.sh
```

Deploy `libquill.so` to `/home/root/quill/` and `riddle-takeover` to
`/home/root/riddle/riddle`, plus `scripts/riddle-takeover.sh`. Launching via
AppLoad (`appload-launch.sh`) detaches into a transient systemd unit, stops
xochitl, runs the diary, and **always restores xochitl on exit** — exit with
the power button, a 5-finger tap, or SIGTERM. If anything wedges:
`ssh root@10.11.99.1 'systemctl start xochitl'`.

## Fonts

The reply hand is [Dancing Script](https://github.com/googlefonts/DancingScript)
(SIL OFL 1.1 — see `riddle/fonts/OFL.txt`).

## License

MIT for everything in this repository (see `LICENSE`). The vendor libraries it
interposes (`libqsgepaper.so`, Qt) are **not** included and must come from
your own device/SDK.

</details>
