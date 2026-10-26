# Device Frames

How Shotbot matches a screenshot to a device and wraps it in a frame.

The data lives in `Sources/Models/Resources/JSON/` (`iPhoneFrames.json`, `iPadFrames.json`, `MacFrames.json`,
`AppleWatchFrames.json`). Frame artwork lives in `Sources/Models/Resources/Frames.xcassets`, and screen masks live in
`Sources/Models/Resources/Masks`.

## How a screenshot is framed

Every device goes through the same steps (`DeviceInfo.framed(using:)`):

1. If the screenshot's resolution differs from the frame's screen opening, scale it to `screenSize`.
2. If a mask exists for the frame, clip the screenshot to it.
3. Place the screenshot at `offSet` on a transparent canvas.
4. Draw the frame on top, once.

A screenshot is matched to a device by its exact pixel size (`DeviceInfo.match(for:)`). If more than one device claims
a size, such as a Display Zoom resolution that equals another phone's native resolution, the user chooses.

## JSON format

One entry per device. Anything written for the first orientation is swapped (width and height, x and y) for the
orientations after it, so a phone's landscape numbers are never repeated.

```json
{
    "name": "iPhone 17 Pro",
    "offSet": [72, 69],
    "resolutions": [
        { "name": "Default", "size": [1206, 2622] }
    ],
    "colors": ["Silver", "Cosmic Orange", "Deep Blue"],
    "orientations": [
        { "orientation": "Portrait", "frame": "iPhone 17 Pro - {color} - Portrait" },
        { "orientation": "Landscape", "frame": "iPhone 17 Pro - {color} - Landscape" }
    ]
}
```

| Key | Meaning |
|---|---|
| `name` | The device's display name. Saved color choices are keyed by it. |
| `screenSize` | Optional. The size of the frame's screen opening. Defaults to the first resolution. See below. |
| `offSet` | Where the screen opening's top-left corner sits in the first orientation's frame. |
| `resolutions` | The screenshot sizes that fit the device, written for the first orientation. `name` says what kind of size it is ("Default", "More Space", "Display Zoom", "Apple Spec"). |
| `colors` | Optional. The colors the frame comes in, with the default first. `{color}` in a frame name is replaced with each one. |
| `colorOffsets` | Optional. For a color whose artwork draws the screen somewhere else than the default color's, its own `offSet`. |
| `orientations` | One frame per orientation, with the first one being the orientation everything else is written in. A later orientation may set its own `offSet` when its art is not an exact transpose of the first, as the iPad Air 2020's is. |
| `viewName` | Optional, on a display with `alternateViews`. What the frames written on the display show, such as "Closed". |
| `alternateViews` | Optional, on a display. Other looks of the screen with their own frame art, as `{ name, offSet, orientations }`. A view only has frames for the orientations it has art for. |
| `displays` | Optional. For a device with several screens (the iPhone Duo), a list of `{ name, offSet, resolutions, orientations }` that replaces writing those keys on the device. The screens share the device's name and colors. |

"Apple Spec" is the iPhone Duo inner display size from Apple's specifications, 1878 × 2670. A mockup built to that size
has no matching frame pixels, so Shotbot scales it to fit the frame, the same way the Frames CLI does. Real simulator
captures are 2007 × 2853 and need no scaling.

Rules enforced by the tests:

- iPhones and iPads need both a portrait and a landscape frame. Watches and Macs have one.
- Landscape numbers are always the portrait numbers swapped, so they are not written down.
- Every resolution must match back to its own device.
- Several devices may share a screenshot size, such as the iPhone 16 Pro, 17, 17 Pro and 18 Pro at 1206 × 2622. The app
  then asks which device it is and remembers the answer.
- Every color of every device has its own frame image.

## Colors

A device with `colors` shows a color picker when its screenshots are on screen. The first color is the default. When
the user picks another one it is saved for that device name and used the next time that device is framed, in the app,
in Shortcuts and in the share extension. Changing the color re-frames the individual and combined images that are on
screen. It does not count as a new framed screenshot and does not auto save again.

Devices that share a name share a saved color. The iPhone Duo's inner and outer screens are one device, so one choice
covers both.

## Views

A view is another look of a screen that has its own frame art, which the user switches between. The iPhone Duo's outer
screen has two: "Closed" is the phone folded with only the outer screen showing, and "Open" shows the phone unfolded
with its back and cameras beside the outer screen. Both use the same 1398 × 2034 screenshot, so the choice can't be
detected from its size. It is a choice in the toolbar menu, next to the color.

```json
"viewName": "Closed",
"alternateViews": [
    {
        "name": "Open",
        "offSet": [1570, 80],
        "orientations": [
            { "orientation": "Portrait", "frame": "iPhone Duo - {color} - Outer Open" }
        ]
    }
]
```

The first view is the one written on the display, and the default. Apple only draws "Open" in portrait, so a landscape
outer screenshot has no view to pick. Every view needs its own screen mask, which the generator makes. A view uses the
device's colors, and the choice is saved per device like the color.

### Folded views

A view can also bend the display's own frame instead of using other art. The iPhone Duo's inner screen has a "Book"
view, which draws the phone opened part of the way, like a book (landscape) or a laptop (portrait):

```json
"viewName": "Flat",
"alternateViews": [
    { "name": "Book", "fold": { "angle": 145 } }
]
```

`angle` is the angle between the two halves in degrees, from 90 (most closed) to 180 (flat). A fold needs no frames, offset
or mask of its own. It uses the display's own, so it exists in every orientation. The image is framed flat first, then
`UIImage.bookFolded(openingAngle:)` splits it at the crease, tilts each half back around it with a perspective transform,
darkens the halves a little (the right or top one more), and adds a soft shadow. The result is on a transparent canvas
that is larger than the frame to make room for the shadow. The left or bottom half reaches a few pixels under the other
half, so the shadow can't show through as a dark line at the crease.

## Why `screenSize` is sometimes needed

A resolution describes what the user's screenshot is. `screenSize` describes what the frame can hold. They are usually
the same, which is why `screenSize` defaults to the first resolution and is left out.

They differ when Apple draws a frame with a screen opening smaller than the real screenshot. The MacBook Neo is the
clearest example:

| | Size |
|---|---|
| Screenshot a Neo takes (from the Frames CLI's catalog, not checked on hardware) | 2816 × 1762 |
| Screen opening in Apple's frame artwork (measured from the frame's transparent area) | 2408 × 1506 |

The opening is about 85.5% of the screenshot's size in both directions (the screenshot is about 17% larger), so the
screenshot is scaled down to 2408 × 1506 before it goes in the frame. The Neo's entry therefore sets `screenSize` explicitly, and its one resolution is the full-size
screenshot. We don't know why Apple draws the artwork at that size.

Four devices need an explicit `screenSize` for this reason: MacBook Neo, MacBook Air 2020, MacBook Air 2022 13 and
iPhone 8 Plus. Every other device is drawn at the screenshot's real pixel size.

## Screen masks

A screenshot is a rectangle, but a screen has rounded corners. A mask is a grayscale image the size of `screenSize`,
cropped to the screen opening, where white is screen and black is everything else. Clipping to it keeps the screenshot's
square corners from showing outside the device.

Masks are bundled, not computed at runtime. They are named `<frame> Mask.png` and loaded by `ScreenMaskCache`. A device
that comes in several colors shares one mask, stored under the default color's frame name. It is the union of every
color's screen. A pixel that one color leaves open and another covers is hidden under that bezel, so it never shows
outside the device. A frame with no mask file is drawn without clipping.

After adding or changing a frame, regenerate the masks from `ShotbotCore`:

```bash
python3 Scripts/generate_screen_masks.py
```

It flood-fills outward from the middle of the expected screen across every pixel that is not bezel and crops the result to `offSet`
and `screenSize`. A pixel counts as bezel when its alpha is at least 250, not only 255, because some frames use 250 to
254 for their bezel. The script stops with an error when:

- the measured opening differs from the JSON by more than 2 pixels. A few frames, mostly the iPhone 11 family and some
  iPads, are off by 1 to 2 pixels, and the script reports each one.
- a color draws the screen somewhere else than the default color. It prints the `colorOffsets` to add to the JSON.
- a color's screen shape differs from the default's by more than a couple of thousand pixels.

Frames are processed in parallel on all cores. The whole set takes about a minute and a half. Doing it one at a time takes
about twelve minutes, because PIL's flood fill is pure Python.

The Models tests rebuild every mask from the frame artwork independently and compare, so a stale or missing mask fails
the suite.

## Adding a device

1. Add the frame PNG for each orientation and color to `Frames.xcassets`, named exactly like the `frame` value with the
   color filled in (`iPhone 17 Pro - Cosmic Orange - Portrait`).
2. Add the device to the matching JSON file. Measure `offSet` from the frame, and add `screenSize` only if screenshots
   are larger than the screen opening. The screenshot rectangle must cover the whole transparent screen. It may overhang
   under the bezel, but it must not leave a gap.
3. Run `python3 Scripts/generate_screen_masks.py`.
4. Run the Models tests. They check masks, composites, orientations, colors, views and size matching.

## Notes

- Apple does not publish landscape artwork for the iPhone 8 / SE or the iPhone 11 Pro. Their landscape frames are the
  portrait frames rotated 90° counter-clockwise, the same way the existing landscape frames that are exact rotations
  relate to their portrait frames.
- Frames are stored sideways in a few cases and carry an orientation tag. The generator and the tests both honor it.
