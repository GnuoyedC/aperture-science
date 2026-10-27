#!/usr/bin/env python3
"""Synthesises the fallback sound pack into ../sounds/synth/*.wav.

All sounds are generated procedurally (no game audio), so the theme can be
redistributed freely. To use your own clips instead (e.g. extracted from your
own Portal installation), simply replace the WAV files with the same names.

Requires: numpy
"""
import wave
from pathlib import Path

import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "sounds" / "synth"
rng = np.random.default_rng(1998)


def t_axis(seconds, rate=RATE):
    return np.arange(int(seconds * rate)) / rate


def env(t, attack, release, total=None):
    """Linear attack, exponential-ish release envelope."""
    total = total if total is not None else t[-1]
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    r = np.clip((total - t) / max(release, 1e-4), 0, 1) ** 2
    return a * r


def lowpass(x, cutoff, rate=RATE):
    """One-pole low-pass filter (cheap and good enough for noise shaping)."""
    alpha = 1 - np.exp(-2 * np.pi * cutoff / rate)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def sweep(t, f0, f1):
    """Sine with an exponential frequency glide from f0 to f1."""
    k = np.log(f1 / f0) / t[-1]
    phase = 2 * np.pi * f0 * (np.exp(k * t) - 1) / k
    return np.sin(phase)


def tone(t, f):
    return np.sin(2 * np.pi * f * t)


def write(name, x, peak=0.7, rate=RATE):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    data = (x * 32767).astype("<i2").tobytes()
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data)
    print(f"{name:22s} {len(x) / rate:5.2f}s")


def click(t, at, freq=1800, decay=0.012, amp=1.0):
    dt = np.clip(t - at, 0, None)
    gate = (t >= at).astype(float)
    return amp * gate * np.exp(-dt / decay) * np.sin(2 * np.pi * freq * dt)


def boot_start():
    # Machine spinning up: rising low drone + filtered air + relay clicks.
    t = t_axis(1.8)
    drone = sweep(t, 45, 120) * 0.6 + sweep(t, 90, 240) * 0.25
    air = lowpass(rng.standard_normal(len(t)), 700) * 2.2
    body = (drone + air * np.linspace(0.2, 1, len(t))) * env(t, 0.5, 0.5)
    relays = sum(click(t, at, 1400 + 300 * i, 0.010, 0.8)
                 for i, at in enumerate((0.15, 0.42, 0.9, 1.25)))
    return body + relays


def system_ready():
    t = t_axis(0.7)
    a = tone(t, 660) * env(t, 0.005, 0.6)
    b = tone(t, 990) * np.where(t > 0.12, 1, 0) * env(t - 0.12, 0.005, 0.5, 0.58)
    return a * 0.6 + b * 0.5 + tone(t, 1980) * env(t, 0.002, 0.2) * 0.08


def ui_focus():
    t = t_axis(0.06)
    return click(t, 0, 2600, 0.008) * 0.6


def ui_click():
    t = t_axis(0.1)
    noise = rng.standard_normal(len(t)) * np.exp(-t / 0.006) * 0.4
    return click(t, 0, 1200, 0.02) + noise


def ui_error():
    t = t_axis(0.28)
    buzz = np.sign(tone(t, 140)) * 0.5 + tone(t, 280) * 0.3
    return lowpass(buzz, 1800) * env(t, 0.004, 0.1) * (0.75 + 0.25 * np.sign(tone(t, 18)))


def portal_activate():
    # Resonant energy "whomp": falling-then-rising glide over filtered noise.
    t = t_axis(1.1)
    core = sweep(t, 180, 720) * env(t, 0.05, 0.6)
    sub = tone(t, 55) * env(t, 0.02, 0.8) * 0.6
    hiss = lowpass(rng.standard_normal(len(t)), 2500) * env(t, 0.1, 0.5) * 1.6
    wobble = 0.75 + 0.25 * tone(t, 9)
    return (core * 0.6 + sub + hiss) * wobble


def login_success():
    t = t_axis(1.0)
    out = np.zeros_like(t)
    for i, f in enumerate((523.25, 659.25, 783.99)):
        start = i * 0.09
        tt = np.clip(t - start, 0, None)
        out += tone(t, f) * (t >= start) * np.exp(-tt / 0.35) * 0.5
    shimmer = tone(t, 1567.98) * np.exp(-np.clip(t - 0.18, 0, None) / 0.2) * (t > 0.18) * 0.08
    return out * env(t, 0.004, 0.25) + shimmer


def login_failure():
    t = t_axis(0.65)
    out = np.zeros_like(t)
    for start, f in ((0.0, 220), (0.24, 155)):
        tt = t - start
        gate = (tt >= 0) & (tt < 0.2)
        sq = np.sign(np.sin(2 * np.pi * f * tt))
        out += sq * gate * np.exp(-np.clip(tt, 0, None) / 0.18)
    # Bit-crush a few short windows for a subtle digital glitch.
    crushed = np.round(out * 4) / 4
    glitch = (np.sin(2 * np.pi * 23 * t) > 0.6)
    return lowpass(np.where(glitch, crushed, out), 2200)


def ambience_loop():
    # Very quiet facility hum. Partials are whole-cycle multiples of the loop
    # length, and the noise is cross-faded with itself, so it loops seamlessly.
    rate = 22050
    seconds = 8.0
    t = t_axis(seconds, rate)
    hum = tone(t, 55) * 0.5 + tone(t, 110) * 0.25 + tone(t, 165) * 0.08
    hum *= 0.85 + 0.15 * tone(t, 0.25)
    n = len(t)
    noise = lowpass(rng.standard_normal(n + rate), 300, rate)
    fade = np.linspace(0, 1, rate)
    body = noise[:n].copy()
    body[:rate] = body[:rate] * fade + noise[n:] * (1 - fade)
    return hum + body * 0.6, rate


def main():
    OUT.mkdir(exist_ok=True)
    write("boot_start.wav", boot_start(), 0.55)
    write("system_ready.wav", system_ready(), 0.45)
    write("ui_focus.wav", ui_focus(), 0.25)
    write("ui_click.wav", ui_click(), 0.35)
    write("ui_error.wav", ui_error(), 0.35)
    write("portal_activate.wav", portal_activate(), 0.55)
    write("login_success.wav", login_success(), 0.5)
    write("login_failure.wav", login_failure(), 0.4)
    amb, rate = ambience_loop()
    write("ambience_loop.wav", amb, 0.18, rate)


if __name__ == "__main__":
    main()
