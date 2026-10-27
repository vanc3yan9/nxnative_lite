# Wargroove 2

## Build and profile

Version 1.2.9, main build `f5bfc69d8bc0732383a513f3cda1ecde`, SDK 16.2.6,
Halley 3.3.48, NVN. The survey-derived memory settings reserve 4 GB with a
256 MB alias region, 256 MB stack region and the NPDM's application pool.
These settings were used for the user-tested iPhone build. All 92 shaders
compile for Mac and iOS.

## Startup audio

Resolved: the named-device, polling `OpenAudioOut` overload was missing from
the host. The iPhone log reached `nnMain`, then aborted at `sdk+0x1e1670`
while trying to connect to `audout:u`, called from `main+0xc11e38`.
The general host fix uses the existing AudioOut implementation with no event.

Resolved in the inspected code: Halley's start method at `main+0xc12484`
calls `StartAudioOut` before publishing its running byte at object +0x19.
Its already runnable priority-28 audio worker asserts that byte at
`main+0xc124e8`; real AudioUnit startup exposed this race on the Mac, while
the silent backend proceeded. The build-gated cut in `patches.py` publishes
the running byte before the start call. This is a workaround for the game's
own initialization order, not a skipped audio call or a disabled feature.
The original also sets the byte without checking the start result.

## Validation and open issues

Audio unit tests cover both polling overloads, guest fields, buffer release,
guarded close/unmap/resume cycles and real device recovery.
Initial Mac testing after the overload fix exposed the running-byte race.
With both fixes, a 40-second Mac run with real audio completed without abort
or an unhandled exception; the audio callback reported zero underruns.
The user confirmed the repaired 1.2.9 iPhone build works on 2026-10-27.
The signed package is approximately 0.53 GB. Device model and long-session
coverage were not recorded.
The local regression harness passed all 92 shader comparisons; no smoke route
exists yet, so that report does not verify gameplay.
Resolved startup movie: the iPhone reached the splash loop, but the demux
worker exited with `Unable to get audio output`: a 2048-byte buffer for a
4096-byte AAC PCM frame. The game reads the decoder byte bound at
`main+0xc1c054`, divides by four at +0xc1c088 to resize a PCM16 vector,
then passes twice its element count at +0xc1c0bc as capacity. The build-gated
cut divides by two instead. This works around the game's allocation arithmetic;
the decoder retains its bounds check.

The movie output format also lacked MIME, so Halley's format callback never
published video readiness. With both corrections, a 55-second Mac run displayed
the opening animation through frame 3163, produced nonzero PCM audio, and exited
cleanly on requested termination without red errors. This verifies startup
movie playback; iPhone testing was subsequently confirmed by the user.

## Found on this game

- [Named-device polling AudioOut](../../../docs/reference/audio.md#named-device-polling-audioout).
- [Decoded output MIME](../../../docs/reference/movies.md#decoded-output-mime).
