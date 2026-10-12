# Map 01 guest art review batches

## Batch 01 — seated guest chibis

Status: **user approved and integrated on 2026-10-12**.

Tank, Gecko, SPF-8, Snowy and Jiwoo seated sprites are 1254×1254 RGBA PNGs. Approved sources now live under `Art/Approved/Guests/`; the files retained here are review-history copies.

## Batch 02 — dialogue and codex portraits

Status: **awaiting visual approval; not integrated into runtime**.

All five files are 1024×1536 RGBA transparent PNGs. The three regular guests receive one full-body portrait each; surprise guest Jiwoo receives a locked base portrait and one facial-expression variant.

| Guest | Review asset | Intended use |
|---|---|---|
| Mimi | `Mimi/Mimi_Portrait_v1.png` | Ordering dialogue and codex detail |
| SPF-8 | `SPF8/SPF8_Portrait_v1.png` | Ordering dialogue and codex detail |
| Snowy | `Snowy/Snowy_Portrait_v1.png` | Ordering dialogue and codex detail |
| Jiwoo | `Jiwoo/Jiwoo_Portrait_Neutral_v1.png` | Default surprise-guest dialogue and codex detail |
| Jiwoo | `Jiwoo/Jiwoo_Portrait_WearySmile_v1.png` | Dry, tired-smile story beat; same pose and costume as neutral |

After approval, promote the selected portraits to `Art/Approved/Guests/<Guest>/`, copy runtime versions into `GodotProject/assets/`, register portrait IDs, and bind Jiwoo's expression variant to the relevant dialogue beat.
