#!/usr/bin/env python3
"""Generate bundled screen masks for every device frame in Resources/JSON.

Each device lists its frames under `orientations`; this script makes one mask per frame. Devices that come
in several colors share one mask, stored under the default color's frame name, and every color is checked
against it.

A screen mask is an 8-bit grayscale PNG the size of a frame's `screenSize`: white is screen, black is
everything else. It is built by flood-filling outward from the center of the frame across every pixel
that is not bezel, so it follows the real screen shape (including asymmetric corners) and reaches
under the bezel's antialiased inner edge. The result is cropped to the frame's `offSet` and `screenSize`.

A pixel counts as bezel when its alpha is at least BEZEL_ALPHA, because some frames use 250 to 254 for their bezel
instead of 255. A frame with no enclosed screen gets no mask, and the app draws the screenshot unclipped.

Run from the ShotbotCore directory after adding or changing a frame:

    python3 Scripts/generate_screen_masks.py

Requires Pillow. The Models tests verify the bundled masks against the frame artwork, so a stale mask
fails the test suite.
"""

import glob
import json
import multiprocessing
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageOps

MODELS = "Sources/Models"
JSON_GLOB = MODELS + "/Resources/JSON/*.json"
FRAMES = MODELS + "/Resources/Frames.xcassets"
OUTPUT = MODELS + "/Resources/Masks"
# How far a frame's measured screen opening may differ from its JSON entry, in pixels.
TOLERANCE = 2
# A pixel with at least this alpha counts as bezel. Some frames use 250-254 for their bezel instead of 255.
BEZEL_ALPHA = 250
# How many pixels a color's screen may differ from the default color's before something is likely wrong.
MAX_COLOR_DIFFERENCE = 2000


def load_frame(name):
    """Loads a frame upright. Some frames are stored sideways with an orientation tag."""
    paths = glob.glob("{}/{}.imageset/*.png".format(FRAMES, name))
    if len(paths) != 1:
        raise SystemExit("Expected one PNG for frame '{}', found {}".format(name, len(paths)))
    return ImageOps.exif_transpose(Image.open(paths[0])).convert("RGBA")


def screen_mask(frame):
    """Returns the full-size screen mask and its bounding box, or None if the frame has no enclosed screen."""
    width, height = frame.size
    alpha = frame.getchannel("A")
    if alpha.getpixel((width // 2, height // 2)) >= BEZEL_ALPHA:
        return None
    mask = alpha.point(lambda value: 255 if value < BEZEL_ALPHA else 0)
    ImageDraw.floodfill(mask, (width // 2, height // 2), 128)
    mask = mask.point(lambda value: 255 if value == 128 else 0)
    box = mask.getbbox()
    if box == (0, 0, width, height):
        return None
    return mask, box


def build_mask(entry):
    """Builds one frame's mask in a worker process: the default color's screen, unioned with every other color's.

    Returns a result dictionary instead of raising, so the main process can report errors in order.
    """
    name = entry["deviceFrame"]
    screen = tuple(entry["screenSize"])
    offset = tuple(entry["offSet"])
    notes = []

    result = screen_mask(load_frame(name))
    if result is None:
        return {"name": name, "mask": None, "notes": notes}

    mask, box = result
    size = (box[2] - box[0], box[3] - box[1])
    off_by = max(abs(size[0] - screen[0]), abs(size[1] - screen[1]),
                 abs(box[0] - offset[0]), abs(box[1] - offset[1]))
    if off_by > TOLERANCE:
        return {"name": name, "error": "{}: screen opening is {}x{} at {} but the JSON entry says {}x{} at {}".format(
            name, size[0], size[1], (box[0], box[1]), screen[0], screen[1], offset)}

    rect = (offset[0], offset[1], offset[0] + screen[0], offset[1] + screen[1])
    cropped = mask.crop(rect)
    del mask

    # Every color shares one mask, so it is the union of each color's screen. A pixel that one color's frame
    # leaves open and another's covers is hidden under that bezel, so including it never shows outside the device.
    undeclared = []
    for variant in entry["variants"]:
        other = screen_mask(load_frame(variant))
        if other is None:
            return {"name": name, "error": "{}: no enclosed screen".format(variant)}
        other_mask, other_box = other
        variant_offset = tuple(entry["variantOffsets"][variant])

        # The shift between this color's screen and the default color's must be the one the JSON declares.
        shift = (other_box[0] - box[0], other_box[1] - box[1])
        declared = (variant_offset[0] - offset[0], variant_offset[1] - offset[1])
        if shift != declared:
            undeclared.append((variant, [offset[0] + shift[0], offset[1] + shift[1]]))
            continue

        variant_rect = (variant_offset[0], variant_offset[1], variant_offset[0] + screen[0], variant_offset[1] + screen[1])
        other_cropped = other_mask.crop(variant_rect)
        differing = ImageChops.difference(other_cropped, cropped).histogram()[255]
        if differing > MAX_COLOR_DIFFERENCE:
            return {"name": name, "error": "{}: screen shape differs from the default color by {} pixels".format(variant, differing)}
        if differing or declared != (0, 0):
            notes.append("    {}: {} pixels differ from the default color{}; using the union".format(
                variant, differing, "" if declared == (0, 0) else " (offset shifted by {})".format(declared)))
        cropped = ImageChops.lighter(cropped, other_cropped)

    if undeclared:
        return {"name": name, "error": "{}: these colors draw the screen somewhere else than the default color. Add them to the "
                "device's colorOffsets in the JSON (first orientation): {}".format(
                    name, ", ".join('"{}": {}'.format(v.split(" - ", 1)[-1] if " - " in v else v, o) for v, o in undeclared))}

    note = "" if off_by == 0 else "  (opening is {}x{} at {}, off by {}px)".format(size[0], size[1], (box[0], box[1]), off_by)
    return {"name": name, "screen": screen, "mask": (cropped.size, cropped.tobytes()), "notes": notes, "note": note}


def collect_frames(device):
    """Lists every frame a device needs a mask for, with the screen it must cover.

    Each entry is the default color's frame, plus the same frame in the device's other colors.
    """
    colors = device.get("colors") or [None]
    frames = []

    # A device with several screens lists them under "displays"; otherwise the device is its one screen.
    for display in device.get("displays") or [device]:
        for index, orientation in enumerate(display["orientations"]):
            # The first orientation is written as authored; later ones swap width and height.
            # The screen is the first resolution unless the display says screenshots are scaled to a smaller one.
            screen = display.get("screenSize") or display["resolutions"][0]["size"]
            offset = display["offSet"]
            if index > 0:
                screen, offset = screen[::-1], offset[::-1]
            offset = orientation.get("offSet") or offset

            # Frame names contain {color} for devices that come in several colors; the first color is the default.
            names = [orientation["frame"].replace("{color}", color) if color else orientation["frame"] for color in colors]

            # A color whose frame draws the screen somewhere else lists its own offset under colorOffsets.
            variant_offsets = {}
            for color, name in zip(colors[1:], names[1:]):
                color_offset = (device.get("colorOffsets") or {}).get(color)
                variant_offsets[name] = (color_offset[::-1] if index > 0 else color_offset) if color_offset else offset

            frames.append({"deviceFrame": names[0], "variants": names[1:], "variantOffsets": variant_offsets,
                           "screenSize": screen, "offSet": offset})

    return frames


def main():
    frames = []
    for path in sorted(glob.glob(JSON_GLOB)):
        for device in json.load(open(path)):
            frames += collect_frames(device)

    os.makedirs(OUTPUT, exist_ok=True)
    expected = set()
    failed = False

    # Flood-filling a frame is slow pure-Python work and every frame is independent, so spread it over all cores.
    with multiprocessing.Pool() as pool:
        for result in pool.imap(build_mask, frames):
            name = result["name"]
            destination = "{}/{} Mask.png".format(OUTPUT, name)
            expected.add(destination)

            if "error" in result:
                print("ERROR", result["error"])
                failed = True
            elif result["mask"] is None:
                if os.path.exists(destination):
                    os.remove(destination)
                print("{:55s} no mask (no enclosed screen)".format(name))
            else:
                size, data = result["mask"]
                Image.frombytes("L", size, data).save(destination, optimize=True)
                for note in result["notes"]:
                    print(note)
                print("{:55s} {}x{}  {:>7,} bytes{}".format(
                    name, result["screen"][0], result["screen"][1], os.path.getsize(destination), result["note"]))
            sys.stdout.flush()

    if failed:
        return 1

    # Remove masks for frames that no longer exist.
    for path in glob.glob(OUTPUT + "/*.png"):
        if path not in expected:
            os.remove(path)
            print("removed stale mask", os.path.basename(path))


if __name__ == "__main__":
    sys.exit(main())
