#!/usr/bin/env python3
"""Screen tour: build the tour for one or more devices, run it in the Connect IQ
simulator, and capture the simulator window at every screen.

    tools/device-tour.py fenix5x [fr245 ...] [--out DIR] [--key KEY.der]

The tour build (monkey.jungle;tour.jungle) opens each screen in turn on a timer,
with 100 sample history entries kept in memory, so no key presses are needed.
After a screen has drawn the app prints "TOUR <nn> <name> used=<b> total=<b>";
this script then grabs the simulator window (X11, through python3-xlib and
Pillow), crops it to the watch display, saves DIR/<device>/<nn>-<name>.png,
and appends the line to DIR/<device>/tour.log. At the end it writes
DIR/<device>/contact.png, every screen on one sheet. --full keeps the whole
simulator window instead of the display. The simulator must be able to open a window on $DISPLAY;
it is started if it is not already running.

The simulator's app storage (/tmp/com.garmin.connectiq/GARMIN/APPS), its
Settings folder, and ~/.Garmin/ConnectIQ/simulator.ini are copied aside first
and put back afterwards, so a tour leaves earlier simulator state as it was.
"""
import argparse
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CIQ_HOME = os.path.expanduser("~/.Garmin/ConnectIQ")
SIM_ROOT = "/tmp/com.garmin.connectiq/GARMIN"
SAVED = [os.path.join(SIM_ROOT, "APPS"), os.path.join(SIM_ROOT, "Settings"), os.path.join(CIQ_HOME, "simulator.ini")]
MARKER = re.compile(r"^TOUR (\d+) (\S+) used=(\d+) total=(\d+)")


def sdk_bin():
    with open(os.path.join(CIQ_HOME, "current-sdk.cfg")) as f:
        return os.path.join(f.read().strip(), "bin")


def backup(dest):
    for path in SAVED:
        if not os.path.exists(path):
            continue
        target = os.path.join(dest, path.strip("/").replace("/", "__"))
        if os.path.isdir(path):
            shutil.copytree(path, target, symlinks=True)
        else:
            shutil.copy2(path, target)


def restore(src):
    for path in SAVED:
        saved = os.path.join(src, path.strip("/").replace("/", "__"))
        if not os.path.exists(saved):
            continue
        if os.path.isdir(saved):
            shutil.rmtree(path, ignore_errors=True)
            shutil.copytree(saved, path, symlinks=True)
        else:
            shutil.copy2(saved, path)


def simulator_running():
    try:
        with socket.create_connection(("127.0.0.1", 1234), timeout=1):
            return True
    except OSError:
        return False


def ensure_simulator(bindir):
    if simulator_running():
        return
    subprocess.Popen([os.path.join(bindir, "connectiq")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    for _ in range(60):
        time.sleep(1)
        if simulator_running():
            time.sleep(2)
            return
    sys.exit("The simulator did not start.")


def simulator_window(xdisplay):
    root = xdisplay.screen().root
    name_atom = xdisplay.intern_atom("_NET_WM_NAME")
    utf8 = xdisplay.intern_atom("UTF8_STRING")
    clients = root.get_full_property(xdisplay.intern_atom("_NET_CLIENT_LIST"), 0)
    for wid in (clients.value if clients else []):
        window = xdisplay.create_resource_object("window", wid)
        prop = window.get_full_property(name_atom, utf8)
        title = prop.value.decode("utf-8", "replace") if prop else ""
        if title.startswith("CIQ Simulator"):
            return window, title
    return None, ""


def display_box(device, window_size):
    """The watch display inside the simulator window: the device image sits
    under the menu bar, centred, and simulator.json gives the display there."""
    import json
    from PIL import Image
    folder = os.path.join(CIQ_HOME, "Devices", device)
    with open(os.path.join(folder, "simulator.json")) as f:
        sim = json.load(f)
    location = sim["display"]["location"]
    image_w, image_h = Image.open(os.path.join(folder, sim["image"])).size
    win_w, win_h = window_size
    left = (win_w - image_w) // 2
    top = win_h - image_h - STATUS_BAR_HEIGHT
    return (left + location["x"], top + location["y"], left + location["x"] + location["width"], top + location["y"] + location["height"])


# Below the device image the simulator window has a status bar of this height.
STATUS_BAR_HEIGHT = 20


def capture(path, device=None):
    from Xlib import X, display
    from PIL import Image
    xdisplay = display.Display()
    try:
        window, title = simulator_window(xdisplay)
        if window is None:
            print("  no simulator window", file=sys.stderr)
            return False
        geometry = window.get_geometry()
        raw = window.get_image(0, 0, geometry.width, geometry.height, X.ZPixmap, 0xFFFFFFFF)
        image = Image.frombytes("RGB", (geometry.width, geometry.height), raw.data, "raw", "BGRX")
        if device is not None:
            image = image.crop(display_box(device, image.size))
        image.save(path)
        return True
    finally:
        xdisplay.close()


def build(bindir, device, key, prg):
    cmd = [os.path.join(bindir, "monkeyc"), "-d", device, "-f", "monkey.jungle;tour.jungle", "-o", prg, "-y", key, "-w"]
    result = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stdout + result.stderr, file=sys.stderr)
        return False
    return True


def contact_sheet(outdir, device, columns=8):
    from PIL import Image, ImageDraw
    shots = sorted(n for n in os.listdir(outdir) if re.match(r"^\d+-.*\.png$", n))
    if not shots:
        return
    images = [Image.open(os.path.join(outdir, n)) for n in shots]
    cell_w = max(i.size[0] for i in images) + 8
    cell_h = max(i.size[1] for i in images) + 22
    rows = (len(images) + columns - 1) // columns
    sheet = Image.new("RGB", (cell_w * min(columns, len(images)), cell_h * rows + 24), (64, 64, 64))
    draw = ImageDraw.Draw(sheet)
    draw.text((6, 6), device, fill=(255, 255, 255))
    for k, (name, image) in enumerate(zip(shots, images)):
        x = (k % columns) * cell_w + 4
        y = (k // columns) * cell_h + 24
        sheet.paste(image, (x, y))
        draw.text((x, y + image.size[1] + 3), name[:-4], fill=(220, 220, 220))
    sheet.save(os.path.join(outdir, "contact.png"))


def tour(bindir, device, prg, outdir, timeout, full):
    os.makedirs(outdir, exist_ok=True)
    for name in os.listdir(outdir):
        if name.endswith(".png") or name == "tour.log":
            os.remove(os.path.join(outdir, name))
    proc = subprocess.Popen([os.path.join(bindir, "monkeydo"), prg, device], cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, start_new_session=True)
    shots = 0
    finished = False
    deadline = time.time() + timeout
    try:
        with open(os.path.join(outdir, "tour.log"), "w") as log:
            for line in proc.stdout:
                line = line.rstrip()
                if line:
                    log.write(line + "\n")
                    log.flush()
                match = MARKER.match(line)
                if match:
                    shot = os.path.join(outdir, "%s-%s.png" % (match.group(1), match.group(2)))
                    if capture(shot, None if full else device):
                        shots += 1
                    print("  %s %s  used %s of %s" % (match.group(1), match.group(2), match.group(3), match.group(4)))
                if line.startswith("TOUR END"):
                    finished = True
                    break
                if time.time() > deadline:
                    print("  timed out", file=sys.stderr)
                    break
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
    if not full:
        contact_sheet(outdir, device)
    return finished, shots


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("devices", nargs="+", help="device ids, as in manifest.xml")
    parser.add_argument("--out", default=os.path.join(REPO, "bin", "tour"), help="output folder (default bin/tour)")
    parser.add_argument("--key", default=os.environ.get("CIQ_DEVELOPER_KEY", os.path.expanduser("~/Garmin/keys/developer_key.der")), help="developer key (.der); default $CIQ_DEVELOPER_KEY or ~/Garmin/keys/developer_key.der")
    parser.add_argument("--full", action="store_true", help="keep the whole simulator window, not just the display")
    parser.add_argument("--timeout", type=int, default=240, help="seconds allowed per device")
    args = parser.parse_args()

    bindir = sdk_bin()
    os.makedirs(os.path.join(REPO, "bin"), exist_ok=True)
    saved = tempfile.mkdtemp(prefix="rtr-tour-state-")
    backup(saved)
    failed = []
    try:
        ensure_simulator(bindir)
        for device in args.devices:
            print(device)
            prg = os.path.join(REPO, "bin", "tour-%s.prg" % device)
            if not build(bindir, device, args.key, prg):
                failed.append(device + " (build)")
                continue
            finished, shots = tour(bindir, device, prg, os.path.join(args.out, device), args.timeout, args.full)
            print("  %d screens%s" % (shots, "" if finished else ", incomplete"))
            if not finished:
                failed.append(device + " (tour)")
    finally:
        restore(saved)
        shutil.rmtree(saved, ignore_errors=True)
    if failed:
        sys.exit("Failed: " + ", ".join(failed))


if __name__ == "__main__":
    main()
