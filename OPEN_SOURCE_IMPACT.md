# Open Source Impact

Fujin Layout is an open-source accessibility project for high-speed Japanese
text input with one hand on a standard keyboard.

## Problem

Many Japanese input workflows assume two-handed QWERTY typing. For users with
one-handed disability, injury, fatigue, or temporary mobility constraints,
keeping normal text-input productivity can require custom hardware, slow
workarounds, or a major loss of speed.

Japanese romaji input also has a structure that ordinary QWERTY does not
support well: most syllables repeat a consonant-vowel pattern. Fujin Layout
uses that structure to make one-handed input more learnable and efficient.

## Why This Matters

- It targets an accessibility need that is rarely addressed by mainstream
  keyboard layouts.
- It works on ordinary keyboards, so users do not need special hardware.
- It is designed for Japanese input, where most global keyboard layout research
  is not optimized.
- It can become a base for right-hand-only variants, cross-platform ports, and
  other accessibility-focused input methods.

## Current Status

Fujin Layout currently has:

- A public AutoHotkey v2 implementation for Windows.
- An MIT License.
- A public roadmap and contribution guide.
- Issue templates for bug reports and accessibility feedback.
- Initial personal benchmark data showing e-typing A rank 231 after roughly
  one week of focused practice.

The project is early-stage, and that is exactly why open-source support can
have high leverage now: better tooling, documentation, packaging, and
validation can turn a working prototype into something more users can actually
try.

## Maintainer Role

The project is primarily maintained by 本城 靖大 (honjoh0823), who designed and
implemented Fujin Layout and its base project, Yamato Layout.

Yamato Layout is a Japanese romaji keyboard layout research project that placed
3rd in the romaji input category at Alternative Typing Contest 2025, according
to the author's public write-up:

https://note.com/_honjoh/n/n6eca0fda500b

## How AI Assistance Would Help

AI coding assistance would directly accelerate work that is difficult for a
small solo-maintained accessibility project:

- Porting from AutoHotkey to macOS and Linux input frameworks.
- Building a non-technical Windows installer.
- Creating automated checks for key-mapping regressions.
- Improving Japanese IME compatibility documentation.
- Producing clearer diagrams, onboarding docs, and training materials.
- Turning personal benchmark notes into reproducible public benchmark scripts.
- Triaging accessibility feedback from users with different typing constraints.

## Near-Term Open Work

The current public roadmap tracks work in:

- Benchmark collection.
- Installer packaging.
- Right-hand-only and cross-platform variants.
- User feedback from one-handed typing use cases.

See:

- Roadmap: ROADMAP.md
- Benchmarks: BENCHMARKS.md
- Issues: https://github.com/honjoh0823/fujin-layout/issues
