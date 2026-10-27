# Home V2: what we are trying to do

Home V2 is a throwaway experiment on `feature/home-v2-layers`: a new default tab, with its own view model, that tests the "layered" approach to framing screenshots and videos. The goal is a UI that responds instantly to every choice (background, device color, canvas shape, blur), with the expensive work done once and reused, and the full-size file made only when someone actually shares, drags, copies or saves it.

It is meant to be thrown away if it doesn't earn its place. Nothing outside `HomeFeature/HomeV2` depends on it, and the legacy Home tab is unchanged.

## Where we started (the original approach)

- **One flattened image per change.** `DeviceInfo.framed(using:)` scales the screenshot, clips it to the screen mask, places it, draws the frame, and (for Partially Open) folds it, all on the CPU with UIKit and a fresh `CIContext`. The result is one `UIImage`.
- **Everything redone on every change.** A device color change re-scales, re-clips, re-draws and re-encodes. The combined image is rebuilt, and each result is encoded to PNG and written to a temp file whether or not anyone exports it.
- **Backgrounds on the exploration branches** (`background-image`, `background-image-actual-image`) are SwiftUI views rendered with `ImageRenderer`, overlaid with the framed image, and baked into `ShareableImage` on every change. That is pre-compositing again, with a full re-render per change.
- **`view-driven-edititing`** shows the screenshots in a SwiftUI view (`FramedScreenshotsComposition`) scaled down for the preview, then exports with `ImageRenderer`. Padding and spacing are hand-scaled to match, which is where preview and export can drift.
- **Video** was framed through `AVAssetExportSession` with a Core Image handler. It took 40–60 s before you saw anything.

Why that hurts: the flattening step is the expensive part, and it was repeated even when only a cheap property (like the background) had changed. SwiftUI as the pixel source also can't run headless (Shortcuts intent, action extension), differs from export in scale and color space, can't go into a video, and is heavy in memory at 2800 px and above.

## Research: how the other apps work

All of this was inferred from the apps' binaries (type names, strings, shader names, linked frameworks). We couldn't see source or time them, so treat it as strong hints, not facts. The one hard data point is the user's own observation that Shareshot is instant: change a background, then drag the result into Finder immediately.

### Shareshot 2.0.5

- **Layered compositor with a layer cache.** Types: `LayerCache`, `LayerCacheMode`, `_flushLayerCache`, `cacheRootFolder`. Log strings: "Dirty: Re-rendering layer", "using cached layer ... because there's no changes", "Skipping render, not invalidated", "Skipping compositing cached layer group". Layer images look to be cached on disk. A change marks one layer dirty; the rest come from cache.
- **Colors are separate bezel images**, one per phone, color and orientation (about 349 assets, e.g. "iPhone 17 - Sage - Portrait"). A color change picks another image rather than tinting. Same idea as our `{color}` frames. A color swap probably re-renders only the frame layer.
- **Backgrounds are procedural**, described as JSON scenes (e.g. `composition_redBokeh`, gaussian blobs in a unit-square coordinate space) and drawn on the GPU. Because the scene is in unit coordinates it renders at any size, so preview and export can't drift. A background change touches one layer.
- **Export is a composite of finished layers.** `ExportCompositor`, `BackgroundCompositor`, `CompositingService`, with Metal compute blends (`compositeAoverB`, `compositeAmultiplyB`, `compositeAreplaceB`) and a `SoftwareRenderer` fallback. Milliseconds of GPU work, which explains the instant export.
- **Lazy drag/copy.** `ExportTransferable` registers data with a load handler, so bytes are made when Finder asks, not at edit time. There is also a file-based variant.
- **Metal in three jobs, none of them "render the framed screenshot":** (1) a Core Image result drawn straight into an `MTKView` for the live preview (`LivePreviewMTKView`), so the preview never leaves the GPU; (2) HDR glow/sparkle effects over the preview (`MetalEDRView`, `edrLightGlow`), which is decoration and not saved; (3) the compute compositor for export.
- **Other details:** a `MemoryPressureMonitor` and logging of free memory around compositing; a separate downsampled "adjustment preview base image"; screen masks derived at runtime from bezel art (`whiteMaskFromGreen`). We chose to bundle masks instead and would keep that.

### Framous 2.0.1

- **One renderer, one description.** Core Image and Metal, driven by a "recipe" JSON. The app and its CLI render the same file (`framous render --recipe layout.json`).
- **Preview is a rendered image at preview scale** (`canvasZoom`, `previewScale`, `baseCanvasImage`), not live SwiftUI. Export renders at native resolution and enforces a 32768 px / 100 MP limit.
- **Duo book mode is a Metal kernel** (`bookFold`, `bookFoldLight`). Simpler than Shareshot: no compute compositor needed.
- **Video:** `AVPlayerLayer` for preview and `AVAssetExportSession` for export, as separate paths. Quality presets of compact, balanced and best.

### What we took from them

| Idea | Source | In Home V2 |
|---|---|---|
| Cache expensive layers, redo only what changed | Shareshot | `LayerCache` actor, layers keyed by what they depend on |
| Preview stays on the GPU | Shareshot | `MetalImageView` drawing Core Image into an `MTKView` |
| Export is a cheap composite of finished layers | Shareshot | `SceneComposer` builds a lazy Core Image graph |
| Make the file only when asked | Shareshot | `Transferable` file representations; PNG made on demand |
| One description for preview and export | Framous, Shareshot | `SceneRecipe` plus one `SceneComposer` for both |
| Procedural backgrounds | Shareshot | `BackgroundRenderer` (gradients, aurora, blur, photo) |
| Fold as a shader | Framous | Not copied. Core Image perspective strips are enough |
| HDR glow effects, runtime mask derivation, compute compositor | Shareshot | Not copied. Not worth it for our app |

## What Home V2 does differently

1. **Layers instead of one flattened image.**
   - *Screen layer:* the screenshot scaled, clipped and placed. Depends on the screenshot and the screen shape, not the frame color.
   - *Frame:* the art for one color, baked once.
   - *Shadow:* depends only on the device outline, so every color shares one, kept as a single gray channel.
   - *Device:* frame over screen, left lazy because putting two finished layers together is nearly free.
   - *Background:* procedural and cheap, or baked once per size when slow (photo, blurred).
2. **Lazy composition.** `SceneComposer` returns a Core Image description, not pixels. Changing the background, padding, aspect or shadow costs almost nothing.
3. **Metal preview.** The same description is drawn into a Metal view at screen size, and into a file at full size.
4. **Lazy export.** PNG is encoded only for share, drag, copy or save, once per picture, off the main thread, and started in the background when edits settle.
5. **Video follows the same model.** The preview pulls frames with `AVPlayerItemVideoOutput`, frames them with the same code the exporter uses, and draws in Metal, so changing background or color shows on the next frame. (AVFoundation live composition fails in the simulator, error -12784.) Export reads, frames and encodes frames directly with the hardware HEVC encoder and copies audio, falling back to `AVAssetExportSession`.
6. **HDR kept end to end.** HDR recordings stay HDR in both preview (10-bit buffers, PQ/HLG, extended-range surface) and export (10-bit HEVC with BT.2020 tags). No frame rate cap.
7. **One pipeline in `ShotbotCore`.** Bundled screen masks, device-centric JSON, colors and views (including the iPhone Duo Open and Partially Open folds), per-screenshot style overrides, shared with video.

## What exists today

- **Tab and UI:** "Home V2" is the default tab. Individual/Combined picker, backgrounds (including a bundled Photo with None/Light/Medium/Strong blur), canvas presets (Fit, Square, 9:16, 16:9, Instagram 4:5), shadow toggle, device color and view menu, Photos and Files import (images and video), share, copy, save to Photos, drag.
- **Video** has the same background, aspect and blur controls as images.
- **Caching:** `LayerCache` is a Swift actor with LRU by memory cost and de-duplication of in-flight builds. It is emptied on a memory warning and when the app goes to the background. `ScreenMaskCache` stays an `NSCache` because legacy code reads it synchronously.
- **Performance work so far:** shadow cached per outline as one gray channel; baked slow backgrounds; parallel photo loading; shared, pre-encoded PNG; direct video exporter. See `PerformanceIdeas.md` for what is left.

## Open questions and risks

- **No measurements yet.** Everything above is reasoned, and the simulator renders Core Image on the CPU. The first job is signposts plus Instruments on a real iPhone.
- **Video export speed:** only ~7% faster than the export session in the simulator. The expected gain is on device.
- **Unverified on device:** HDR brightness in preview versus export, video share/save from the V2 UI, Share/Copy after the shared-PNG change, and memory of the 16-bit HDR preview surface on older phones.
- **Partially Open fold** still goes through the CPU for images.
- **Decision to make:** keep V2 and migrate the legacy tab onto it, port selected ideas (layer cache, lazy export) into legacy, or discard. The Shortcuts intent and action extension need headless rendering, which the Core Image pipeline supports and SwiftUI `ImageRenderer` does not.
- **Tests:** `HomeFeatureTests` doesn't compile (pre-existing missing `FileManaging`), so V2 has no unit tests beyond the shared `Models` tests.

## Branches

- `feature/frame-screen-mask`: the single framing pipeline (PR #29 open).
- `feature/video-support`: video framing, HDR, Partially Open for video, colors and views (pushed, no PR).
- `feature/home-v2-layers`: Home V2 (local, not pushed, no PR).
