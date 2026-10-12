# Southwind dynamic art · review batch DYN-A

2026-10-12 generated for user review. These files are not Approved and are not connected to Godot yet.

| File | Canvas | Purpose |
|---|---:|---|
| `CandleFlame_Southwind_v1.png` | 256×256 RGBA | Independent table-lamp flame; gentle scale/offset modulation is allowed. |
| `CandleGlow_Southwind_v1.png` | 512×512 RGBA | Independent soft glow for table and hanging lamps; alpha/additive blending is allowed. |
| `Sunny_Southwind_CenterIdle_00.png` | 512×512 RGBA | Center-idle neutral frame. |
| `Sunny_Southwind_CenterIdle_01.png` | 512×512 RGBA | Breathing-up frame; feet remain on the same baseline. |
| `Sunny_Southwind_CenterIdle_02.png` | 512×512 RGBA | Breathing-return frame; feet remain on the same baseline. |

The flame and glow were generated with the built-in image generator and normalized to runtime dimensions. Sunny uses the previously approved `Sunny_Southwind_Idle_v1.png` as the single visual source; frames 01–02 only apply a 1–2 px vertical breathing change after normalization, avoiding AI redraw jitter. All PNGs use genuine transparency and contain no text or UI.

Approval flow: after visual confirmation, copy the five files to `Art/Approved/Animation/Southwind/` and `GodotProject/assets/`, update `Art/manifest.json`, then run Godot import and a 10-second loop check.

## DYN-01 / DYN-02 follow-up review batch

| File | Spec | Review purpose |
|---|---|---|
| `Island_Southwind_WaterMask_v1.png` | 1672×941 RGBA | Pixel-aligned water-only mask derived from the actual runtime background; protected scene areas are black. |
| `Island_Southwind_WaterFoam_v1.png` | 1672×941 RGBA | Sparse pale-cyan foam at the natural rocky shoreline only; the dock is not outlined. |
| `Island_Southwind_LightAnchors_v1.json` | UTF-8 JSON | Eight source-pixel anchors with type, phase and scale. |
| `Island_Southwind_WaterMask_QA_v1.jpg` | 1672×941 RGB | Cyan mask overlay for visual alignment review; QA only. |
| `Island_Southwind_WaterFoam_QA_v1.jpg` | 1672×941 RGB | Foam composited over the runtime background; QA only. |
| `Island_Southwind_LightAnchors_QA_v1.jpg` | 1672×941 RGB | Candle/glow alignment plus numbered anchor markers; QA only. |

The foam began as a built-in image-generator edit using `Island_Background.png` as the exact alignment reference, then its color and maximum alpha were normalized mechanically. The mask is deterministic and inset three pixels to protect wood and scene edges. These six follow-up files remain `Review` assets until explicit confirmation.

## Guest seated breathing · batch 01

2026-10-12 review-only animation frames for Bobo, Coco, Horn, Mimi and Tank. Each guest has three 1254×1254 RGBA frames under `Guests/<Guest>/`:

- `*_SeatedIdle_00_v1.png`: exact approved seated sprite, neutral frame.
- `*_SeatedIdle_01_v1.png`: 0.3% horizontal / 0.5% vertical inhale expansion, bottom baseline locked.
- `*_SeatedIdle_02_v1.png`: 0.3% horizontal / 0.5% vertical exhale relaxation, bottom baseline locked.

Recommended loop: `00 → 01 → 02 → 01`, approximately 0.28 seconds per frame, with a small per-seat phase offset. Generated redraw tests were rejected because shell, feet and props drifted; the retained files are deterministic derivatives of the approved sprites, so identity, facial expression, equipment and transparent canvas remain locked.

These 15 frames were approved on 2026-10-12 and copied to `Art/Approved/Animation/Southwind/Guests/`; the copies here remain as review history. Godot runtime integration is intentionally deferred while the next art batch is produced.

## Guest seated breathing · batch 02

Review-only three-frame sets for Gecko, SPF-8, Snowy and Jiwoo are stored under `Guests/<Guest>/`. They use the same 1254×1254 RGBA specification, bottom-locked 0.3%–0.5% deformation, `00 → 01 → 02 → 01` loop order, and 0.28-second frame recommendation as approved batch 01.

The neutral `00` frames are byte-identical to the approved seated sprites. All clipboard, sunscreen arms and props, scarf/map/luggage, laptop and backpack silhouettes remain unchanged. These 12 files are not Approved and are not connected to Godot.
