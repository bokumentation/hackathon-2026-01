"""Render selected VCD signals as digital waveform figures (PNG).

Usage:
    python plot_waveforms.py in.vcd out.png --t0 0 --t1 600 \
        transmission_begin framing_ok host_full fault
"""

import argparse

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from vcdvcd import VCDVCD


def find_signal(vcd, needle):
    for name in vcd.signals:
        if name.split(".")[-1] == needle:
            return name
    for name in vcd.signals:
        if needle in name:
            return name
    raise KeyError(needle)


def series(vcd, needle, t0, t1, ns):
    name = find_signal(vcd, needle)
    pts = [(t * ns, int(v, 2) if v else 0) for t, v in vcd[name].tv]
    in_window = [(t, v) for t, v in pts if t0 <= t <= t1]
    if not in_window:
        in_window = pts[:1]
    start_val = [v for t, v in pts if t <= t0]
    start = start_val[-1] if start_val else 0
    times = [t0] + [t for t, _ in in_window]
    values = [start] + [v for _, v in in_window]
    return times, values


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("vcd")
    parser.add_argument("out")
    parser.add_argument("--t0", type=float, default=None)
    parser.add_argument("--t1", type=float, default=None)
    parser.add_argument("--title", default=None)
    parser.add_argument("signals", nargs="+")
    args = parser.parse_args()

    vcd = VCDVCD(args.vcd)
    ns = float(vcd.timescale.get("factor", 1e-9)) * 1e9
    all_times = []
    for sig in args.signals:
        name = find_signal(vcd, sig)
        all_times += [t * ns for t, _ in vcd[name].tv]
    t0 = args.t0 if args.t0 is not None else min(all_times)
    t1 = args.t1 if args.t1 is not None else max(all_times)

    fig, axes = plt.subplots(
        len(args.signals), 1, sharex=True, figsize=(11, 0.6 * len(args.signals) + 1)
    )
    if len(args.signals) == 1:
        axes = [axes]

    for ax, sig in zip(axes, args.signals):
        times, values = series(vcd, sig, t0, t1, ns)
        ax.step(times, values, where="post", linewidth=1.3)
        ax.set_ylabel(sig, rotation=0, ha="right", va="center", fontsize=8)
        ax.set_ylim(-0.25, 1.25)
        ax.set_yticks([0, 1])
        ax.set_xlim(t0, t1)
        ax.grid(True, axis="x", linestyle=":", linewidth=0.5)
        ax.tick_params(axis="both", labelsize=8)
        for spine in ("top", "right"):
            ax.spines[spine].set_visible(False)

    axes[0].set_title(args.title or args.vcd.split("/")[-1], fontsize=10)
    axes[-1].set_xlabel("time (ns)")
    fig.tight_layout()
    fig.savefig(args.out, dpi=140)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
