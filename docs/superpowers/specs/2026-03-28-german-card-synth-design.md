# German Card Index Synthetic Data Generator

**Date:** 2026-03-28
**Status:** Approved

## Goal

Generate synthetic card crop images with German corner indices (**B** for Bube/Jack, **D** for Dame/Queen) so the rank classifier (notebook 02) recognizes both English and German card styles. The synthetic images are added to the existing `J` and `Q` rank folders.

## Decisions

- **Class mapping:** B → J class, D → Q class. Classifier stays at 13 output classes.
- **Volume:** ~500 synthetic images per rank (B and D), matching the existing Kaggle crop volume per class.
- **Delivery:** New notebook `notebooks/03_german_card_synth.ipynb`, run before notebook 02.
- **Approach:** Corner-overlay rendering with PIL (Approach 1). Pure programmatic generation, no seed images required.

## Rendering Pipeline

Each synthetic card crop image is generated as follows:

1. **Canvas:** Create image at ~128×180px (matching typical YOLO crop aspect ratio). Background is randomized white/off-white/cream.
2. **Rank letter:** Draw "B" or "D" in the upper-left corner. Randomize:
   - Font family (serif, sans-serif, bold — from available system/Colab fonts)
   - Font size (slight variation)
   - Color (black, dark red, dark blue — matching real card ink colors)
3. **Suit symbol:** Draw one of ♠♥♦♣ below/beside the rank letter. Color matches suit convention (red for ♥♦, black for ♠♣).
4. **Mirror:** Repeat rank + suit in the lower-right corner (rotated 180°), as on real cards.
5. **Center fill (optional):** Simple geometric pip pattern or blank — the classifier primarily uses corner features.

## Augmentation Pipeline

Each rendered base image is augmented to produce multiple variations:

- Random rotation: ±15°
- Brightness jitter: ±20%
- Contrast jitter: ±20%
- Gaussian noise: σ 0–10
- Slight color tint (simulating lighting variation)
- Random border/background bleed (simulating imperfect YOLO crops)
- Minor perspective warp

With ~50 base card designs (varying font, suit, layout) × ~10 augmentations each = ~500 images per rank.

## Output

- `data/rank_cards/J/synth_B_{index}.jpg` — 500 images
- `data/rank_cards/Q/synth_D_{index}.jpg` — 500 images
- All synthetic images prefixed with `synth_` for easy identification/removal.

## Notebook Structure

1. **Setup** — imports (PIL, numpy), configuration constants
2. **Card rendering function** — `render_card_crop(rank_letter, suit, font, ...)` → PIL Image
3. **Augmentation function** — `augment_card(image)` → PIL Image
4. **Generate B → J folder** — render + augment, save to `data/rank_cards/J/`
5. **Generate D → Q folder** — render + augment, save to `data/rank_cards/Q/`
6. **Visual QA** — display 4×4 grid of random samples from each rank
7. **Summary stats** — print image counts per rank folder (before and after generation)

## Dependencies

- `Pillow` (PIL) — image rendering and augmentation
- `numpy` — noise generation, random sampling

Both already required by notebook 02. No new dependencies.

## Integration with Notebook 02

No changes to notebook 02 are needed. It loads all images from `data/rank_cards/{rank}/` folders. The synthetic images are placed directly into the `J` and `Q` folders, so they're automatically included in training.

## Limitations

- Rendered cards won't perfectly match real card textures, but strong augmentation should bridge the gap.
- All generated cards use the same basic layout. If real German-indexed decks vary significantly in design, the model may still struggle with unseen styles.
- Future improvement: add seed-image augmentation mode where real B/D card photos are augmented instead of rendering from scratch.
