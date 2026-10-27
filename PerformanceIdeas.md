# Home V2 performance ideas

What is left after the layered pipeline, shadow caching, baked backgrounds, parallel loading, shared PNG export and the direct video exporter. Ordered roughly by expected payoff. Nothing here has been measured yet; see item 0.

## 0. Measure first
- Add `os_signpost` intervals around layer builds, scene composition, background bakes, PNG encode, each video preview frame and each export frame.
- Profile on a real iPhone with Instruments (Core Image, Metal System Trace, Time Profiler). The simulator renders Core Image on the CPU, so its numbers say little about video.
- Record a baseline (time to first picture, time to change color, time to share, export time per minute of video) before changing anything below.

## Screenshots and layers
1. **Lower-resolution layers for editing.** Layers are built at full size (18–70 MB each) but the Metal view shrinks them on every redraw. Build preview layers at about 2x the screen size, and build full-size layers only for export or in the background.
2. **Keep the Partially Open fold on the GPU.** The fold currently reads pixels back to the CPU, folds a bitmap with `UIImage.partiallyOpened`, and uploads it again, creating a new `CIContext` each time. Fold with the Core Image strips we already use for video, and share one context.
3. **Compose the scene less often.** The view recomposes the Core Image graph for every page on every update. Remember the result until the recipe or the layers change.
4. **Coalesce redraws.** Set `MetalImageView.image` at display-link cadence instead of on every state change while a control is dragged.
5. **Half-resolution shadow.** The shadow is a blur, so it can be baked at half size and scaled up when composed, for another 4x memory saving on top of the single channel.
6. **Cache budget from device memory.** Replace the fixed 700 MB `LayerCache` budget with a fraction of `ProcessInfo.physicalMemory`.
7. **Pre-warm.** Load the frame art, screen masks and default shadow for common devices on launch, before the user picks anything.
8. **JPEG/HEIC export.** When the background is opaque, offer JPEG or HEIC. Encoding is much faster and files are far smaller than a 4757×3202 PNG. A PNG without an alpha channel is also quicker to encode when nothing is transparent.

## Video preview
9. **Do less per frame.** Each frame runs the mask blend, frame, shadow and background as separate steps. Bake the frame with its screen cutout once and the background with its shadow once, so a frame is just the video drawn between two ready layers.
10. **Ask the player for smaller frames.** The preview reads full-size frames but only shows a screen-sized picture. Request scaled frames from `AVPlayerItemVideoOutput` to save decode and conversion work.
11. **Skip frames when behind.** If drawing a frame takes longer than the display interval, drop to the newest frame instead of queueing.
12. **Cheaper Partially Open fold.** The fold is about 140 thin strips per frame. Use fewer, wider strips, or compute a single warp once and apply it per frame.
13. **16-bit HDR surface.** Check memory and frame drops of the `.rgba16Float` HDR preview on older phones; fall back to 8-bit SDR preview there if needed.

## Video export
14. **Export in the background.** Start exporting once edits settle (like the PNG pre-encode) so Share finds a finished file. Cancel when the recipe changes.
15. **Progress and cancel.** Show progress from the frame count and let the user cancel. `VideoExporter` already supports task cancellation.
16. **Quality presets.** Offer compact, balanced and best, mapped to the bits-per-pixel factor in `VideoExporter` (currently 0.07), and a cap on resolution.
17. **Pipeline the render.** Render the next frame while the encoder is still working on the previous one, using a small ring of pixel buffers, instead of one frame at a time.
18. **Avoid HDR when not needed.** Offer an SDR export of an HDR recording for apps and sites that mishandle HDR; it encodes faster and is smaller.
19. **Reuse the preview's baked layers.** Pass the same baked background and shadow to the exporter so nothing is redrawn at export time.

## Verification still needed
- HDR brightness of the preview against the exported file, on a real device.
- Share and save of a video from the Home V2 UI after the exporter change.
- Share, drag and copy of an image after the shared-PNG change, including editing right before sharing.
- `HomeFeatureTests` does not compile (pre-existing missing `FileManaging`).
