## regress.py check (quick): PASS

Baseline `b7a5cd43453722d448e07407d88a9c05ed294492` b7a5cd434537, candidate `worktree` b7a5cd434537 (+ uncommitted changes); Apple M2 Max, macOS 27.0.1, Xcode 27.1; 1.1 s

| game | status | shaders (base → cand) | newly failing | newly building | changed MSL | interface (new / known) | boot | fps p50 | frame p99 ms | peak MB | prepare s | new RED |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 战律2 Wargroove 2 `0100AD401A2F0000` | **PASS** | 92/92 → 92/92 | 0 | 0 | 0 | 0 / 0 | – | – | – | – | – | – |

### 战律2 Wargroove 2 `0100AD401A2F0000`: PASS
  - time: chain 0.5 s

## Lightweight delivery checks

- iOS source compile: 179 files, zero failures (Fire Emblem profile).
- Unsigned iOS smoke project: Release build succeeded, including Swift launcher and external resource validator; no game data needed.
- Python resource exporter and existing Xcode workflow tests: 6 passed.
- Foundation validator test: missing files, valid files, cached validation, corruption, incomplete copy, retry, receipt and escaping symlink cases passed.
- Shell syntax and whitespace checks passed.

The regression discovery found only the Wargroove 2 build in the expected directory layout. The table above covers shader comparison only; blank boot metrics are not gameplay passes. No physical iPhone installation, multi-game startup or large real-data export was tested in this change. The initial sandboxed Xcode invocation failed due to local simulator service access; the unrestricted smoke build succeeded.
