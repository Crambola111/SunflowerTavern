# Southwind dynamic art · approved batch DYN-A

User approved on 2026-10-12. The five files are archived here and copied to `GodotProject/assets/` for runtime use.

| File | Canvas | Purpose |
|---|---:|---|
| `CandleFlame_Southwind_v1.png` | 256×256 RGBA | Independent table-lamp flame; gentle scale/offset modulation is allowed. |
| `CandleGlow_Southwind_v1.png` | 512×512 RGBA | Independent soft glow for table and hanging lamps; alpha/additive blending is allowed. |
| `Sunny_Southwind_CenterIdle_00.png` | 512×512 RGBA | Center-idle neutral frame. |
| `Sunny_Southwind_CenterIdle_01.png` | 512×512 RGBA | Breathing-up frame; feet remain on the same baseline. |
| `Sunny_Southwind_CenterIdle_02.png` | 512×512 RGBA | Breathing-return frame; feet remain on the same baseline. |

The flame and glow were generated with the built-in image generator and normalized to runtime dimensions. Sunny uses the previously approved `Sunny_Southwind_Idle_v1.png` as the single visual source; frames 01–02 only apply a 1–2 px vertical breathing change after normalization, avoiding AI redraw jitter. All PNGs use genuine transparency and contain no text or UI.

Runtime integration uses the real three-frame Sunny loop and independent candle flame/glow layers. Static file and code checks passed; a local Godot window and 10-second visual loop check remain required because this environment has no Godot executable.

## Guest seated breathing · approved batch 01

User approved Bobo, Coco, Horn, Mimi and Tank on 2026-10-12. Each guest has three 1254×1254 RGBA frames under `Guests/<Guest>/`:

- `*_SeatedIdle_00_v1.png`: byte-identical approved seated neutral sprite.
- `*_SeatedIdle_01_v1.png`: subtle inhale frame with the bottom baseline locked.
- `*_SeatedIdle_02_v1.png`: subtle exhale frame with the bottom baseline locked.

Recommended loop: `00 → 01 → 02 → 01`, approximately 0.28 seconds per frame plus a small per-seat phase offset. The 15 approved frames are now copied to `GodotProject/assets/`, registered in `ArtCatalog.GUEST_IDLE_SEQUENCES`, and mounted by the live seat renderer. Guests without a confirmed frame set keep the restrained transform-only fallback; no portrait is substituted for a chibi.
