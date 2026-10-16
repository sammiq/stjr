#!/usr/bin/env python3
"""Convert the Amiga version's music to ProTracker modules.

    tools/amiga_music.py OUT [DIR]          write OUT/<song>.mod for every TREK*.SNG
    tools/amiga_music.py --wav OUT [DIR]    and render each to OUT/<song>.wav

DIR defaults to orig/AMIGA/StarTrek25thAnnivAGA/data/database. --wav needs
an ffmpeg built with libopenmpt.

The songs are "The Player 4.1A" (P41A) modules with the sample data taken
out: the letter before .SNG names the shared bank (SAMPLES.A-D) that the
sample table points into. snd.bin is the 68k replayer; the notes below
are from its code.

P41A layout, offsets counted from after the 'P41A' magic:

    4   byte  patterns (unused here)       5   byte  positions
    6   byte  samples                      7   byte  0
    8   long  track data                   12  long  track table
    16  long  sample data (the game passes the bank instead)
    20  samples, 16 bytes each: long start, word length, long loop start,
        word loop length (lengths in words), byte 0, byte volume,
        word finetune * 74 (a byte offset into the period tables)

The track table has four words per position, each an offset into the
track data, ended by $FFFF (loop to the start). A track is 4-byte events
c1 c2 c3 c4: note * 2 | sample bit 4 in c1, sample bits 0-3 << 4 | effect
in c2, the parameter in c3. A positive c4 is that many empty rows after
the event, a negative one repeats the event -c4 more rows. c1 >= $80 is
a reference instead: play the c2 + 1 events at track data + c3c4, then
carry on after it.

Effects that differ from ProTracker: 8 is the arpeggio (0 is nothing),
the volume slides (5, 6, A) take a signed amount subtracted from the
volume, and D ignores its parameter. F00 stops the song, and the tracks
have nothing after it; players that ignore F00 in a MOD would carry on
into the rest of the pattern, so a D00 goes on the same row to end it.
"""

import argparse
import os
import shutil
import struct
import subprocess
import sys

sys.path.insert(0, os.path.dirname(__file__))
from resource import Archive  # noqa: E402

DEFAULT_DIR = os.path.join(os.path.dirname(__file__), "..", "orig", "AMIGA",
                           "StarTrek25thAnnivAGA", "data", "database")

# ProTracker periods for notes 1-36 (C-1 to B-3), finetune 0
PERIODS = [856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
           428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
           214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113]


def slide(c3):
    """A signed volume slide amount as a ProTracker xy parameter."""
    if c3 >= 0x80:
        return min(0x100 - c3, 15) << 4
    return min(c3, 15)


def cell(c1, c2, c3):
    """A P41A event as a ProTracker pattern cell."""
    note = (c1 & 0x7E) >> 1
    period = PERIODS[note - 1] if 1 <= note <= 36 else 0
    smp = (c1 & 1) << 4 | c2 >> 4
    fx, par = c2 & 0x0F, c3
    if fx == 0:
        par = 0
    elif fx == 8:
        fx = 0
    elif fx in (5, 6, 0x0A):
        par = slide(c3)
    elif fx == 0x0D:
        par = 0
    return bytes([(smp & 0x10) | period >> 8, period & 0xFF,
                  (smp & 0x0F) << 4 | fx, par])


def track(song, trkdat, pos):
    """The rows of one track, as long as they're asked for."""
    def event(pos):
        c1, c2, c3, c4 = song[pos:pos + 4]
        c = cell(c1, c2, c3)
        yield c
        if c4 >= 0x80:
            yield from [c] * (0x100 - c4)
        else:
            yield from [bytes(4)] * c4

    while True:
        if song[pos] & 0x80:
            count, ref = song[pos + 1], trkdat + (song[pos + 2] << 8 | song[pos + 3])
            for k in range(count + 1):
                yield from event(ref + 4 * k)
        else:
            yield from event(pos)
        pos += 4


def pattern(song, trkdat, offs):
    """One position's pattern: the four tracks row by row, up to a break
    or the end of the song. Also whether the song ends here."""
    chans = [track(song, trkdat, trkdat + o) for o in offs]
    rows = []
    while len(rows) < 64:
        row = [next(c) for c in chans]
        stop = any(c[2] & 0x0F == 0x0F and c[3] == 0 for c in row)
        if stop and not any(c[2] & 0x0F == 0x0D for c in row):
            free = [i for i, c in enumerate(row) if c[2] & 0x0F == 0 and c[3] == 0]
            if free:
                c = row[free[0]]
                row[free[0]] = c[:2] + bytes([c[2] | 0x0D, 0])
            elif len(rows) < 63:
                # no room on the row: the break goes on an empty one after it
                rows.append(b"".join(row))
                row = [b"\0\0\x0D\0"] + [bytes(4)] * 3
        rows.append(b"".join(row))
        # B, D and F00 end the pattern after this row, and its tracks with it
        if stop or any(c[2] & 0x0F in (0x0B, 0x0D) for c in row):
            break
    return b"".join(rows).ljust(1024, b"\0"), stop


def convert(name, song, bank, warn):
    if song[:4] != b"P41A":
        raise ValueError(f"{name}: not a P41A module")
    npos, nsmp = song[5], song[6]
    trkdat, trktab, _ = (x + 4 for x in struct.unpack_from(">III", song, 8))

    out = bytearray(name.split(".")[0].encode().ljust(20, b"\0"))
    samples = []
    for i in range(nsmp):
        start, length, loop, looplen, vol, fine = struct.unpack_from(">IHIHxBH", song, 20 + 16 * i)
        data = bank[start:start + 2 * length]
        if len(data) < 2 * length:
            warn(f"sample {i + 1} runs {2 * length - len(data)} bytes past the bank; padded with silence")
            data += bytes(2 * length - len(data))
        if fine % 74 or fine // 74 > 15:
            warn(f"sample {i + 1} finetune offset {fine} isn't a period table; using 0")
            fine = 0
        out += bytes(22) + struct.pack(">HBBHH", length, fine // 74, vol,
                                       (loop - start) // 2, looplen)
        samples.append(data)
    for i in range(nsmp, 31):
        out += bytes(22) + struct.pack(">HBBHH", 0, 0, 0, 0, 1)

    patterns = []
    order = []
    for p in range(npos):
        offs = struct.unpack_from(">4H", song, trktab + 8 * p)
        pat, stop = pattern(song, trkdat, offs)
        if pat not in patterns:
            patterns.append(pat)
        order.append(patterns.index(pat))
        if stop:
            break

    out += bytes([len(order), 0x7F]) + bytes(order).ljust(128, b"\0") + b"M.K."
    for pat in patterns:
        out += pat
    for data in samples:
        out += data
    return bytes(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--wav", action="store_true", help="also render each song to a .wav")
    ap.add_argument("out")
    ap.add_argument("dir", nargs="?", default=DEFAULT_DIR)
    args = ap.parse_args()
    if args.wav and not shutil.which("ffmpeg"):
        sys.exit("--wav needs ffmpeg (with libopenmpt)")

    arc = Archive(args.dir)
    banks = {}
    os.makedirs(args.out, exist_ok=True)
    for name in arc.names("SNG"):
        letter = name.split(".")[0][-1]
        if letter not in banks:
            with open(os.path.join(args.dir, f"SAMPLES.{letter}"), "rb") as f:
                banks[letter] = f.read()

        def warn(msg):
            print(f"{name}: {msg}", file=sys.stderr)

        mod = convert(name, arc.read(name), banks[letter], warn)
        path = os.path.join(args.out, name.split(".")[0].lower() + ".mod")
        with open(path, "wb") as f:
            f.write(mod)
        print(f"{path}  {len(mod)} bytes")
        if args.wav:
            wav = path[:-4] + ".wav"
            r = subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "libopenmpt",
                                "-i", path, wav], capture_output=True, text=True)
            if r.returncode:
                sys.exit(f"ffmpeg failed on {path}:\n{r.stderr}")
            print(wav)


if __name__ == "__main__":
    main()
