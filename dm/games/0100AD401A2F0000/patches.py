# Halley starts its audio worker before StartAudioOut, but publishes its running
# flag only after that call returns. The worker asserts the flag in its first
# update. Apple's synchronous AudioUnit start exposes this game-code race.
# Publish the flag before starting playback; the original also sets it without
# checking the StartAudioOut result. Restricted to the inspected 1.2.9 main.
CUTS = {
    'f5bfc69d8bc0732383a513f3cda1ecde': [
        (0xc124b0, '608200912b8c01942800805268660039', '280080526866003960820091298c0194',
         'Publish Halley audio running before starting the device; worker already runnable'),
        # The movie reader divides the decoder's byte bound by four, resizes a
        # PCM16 vector, then passes twice its element count as byte capacity.
        # That halves the bound (4096 -> 2048), aborts the demux worker and leaves
        # the main thread waiting forever for video format. Work around the
        # game's allocation arithmetic, not the decoder's bounds check.
        (0xc1c088, '01fd42d3', '01fd41d3',
         'Size the PCM16 movie vector in two-byte samples, not four-byte samples'),
    ],
}
