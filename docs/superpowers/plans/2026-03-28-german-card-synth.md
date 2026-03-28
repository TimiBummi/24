# German Card Synthetic Data Generator — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create notebook `03_german_card_synth.ipynb` that generates ~500 synthetic card crop images each for B (Bube→J) and D (Dame→Q) ranks, matching existing notebook style.

**Architecture:** PIL renders card crops with German rank letters and suit symbols on randomized backgrounds. Each base design is augmented (rotation, brightness, noise, perspective) to produce variations. Output goes directly into `data/rank_cards/J/` and `data/rank_cards/Q/`.

**Tech Stack:** Pillow (PIL), NumPy, matplotlib (for visual QA grid)

**Spec:** `docs/superpowers/specs/2026-03-28-german-card-synth-design.md`

---

### Task 1: Create notebook with setup cell

**Files:**
- Create: `notebooks/03_german_card_synth.ipynb`

- [ ] **Step 1: Create notebook with markdown header and setup code cell**

The notebook follows the same style as notebooks 01 and 02 (markdown header, then setup cell).

Markdown cell:
```markdown
# German Card Index — Synthetic Data Generator

Generate synthetic card crop images with German corner indices (**B** for Bube/Jack, **D** for Dame/Queen) to augment the rank classifier training data.

- **B** (Bube) → saved to `J` class folder
- **D** (Dame) → saved to `Q` class folder
- **Output:** ~500 images per rank into `data/rank_cards/{J,Q}/`

Run this notebook **before** Notebook 02 (rank classifier training) so the synthetic images are included in the training set.

> **Runtime:** CPU is sufficient — no GPU needed for image generation.
```

Code cell:
```python
import os
import random
import numpy as np
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import matplotlib.pyplot as plt

random.seed(42)
np.random.seed(42)

# Configuration
RANK_DIR = "data/rank_cards"
CARD_WIDTH = 128
CARD_HEIGHT = 180
NUM_IMAGES_PER_RANK = 500

# German index → target class folder
GERMAN_RANKS = {
    "B": "J",   # Bube → Jack
    "D": "Q",   # Dame → Queen
}

# Suit symbols and their colors
SUITS = {
    "♠": (0, 0, 0),        # black
    "♣": (0, 0, 0),        # black
    "♥": (200, 0, 0),      # red
    "♦": (200, 0, 0),      # red
}

print(f"Will generate {NUM_IMAGES_PER_RANK} images each for: {list(GERMAN_RANKS.keys())}")
print(f"Output: {RANK_DIR}/J/ and {RANK_DIR}/Q/")
```

- [ ] **Step 2: Verify the cell runs locally (optional) or review for correctness**

The cell should print:
```
Will generate 500 images each for: ['B', 'D']
Output: data/rank_cards/J/ and data/rank_cards/Q/
```

---

### Task 2: Add font discovery cell

**Files:**
- Modify: `notebooks/03_german_card_synth.ipynb`

- [ ] **Step 1: Add markdown cell**

```markdown
## 1. Font Discovery

Find available fonts on the system (Colab or local). Card rank letters need serif and sans-serif fonts at various weights to create visual diversity.
```

- [ ] **Step 2: Add code cell for font discovery**

```python
# Discover available TrueType fonts for rendering rank letters
# On Colab, fonts live in /usr/share/fonts/; locally they vary by OS
import subprocess

def find_system_fonts():
    """Find .ttf font files on the system."""
    font_dirs = [
        "/usr/share/fonts",
        "/usr/local/share/fonts",
        "/System/Library/Fonts",         # macOS
        "C:\\Windows\\Fonts",            # Windows
    ]
    fonts = []
    for d in font_dirs:
        if os.path.isdir(d):
            for root, _, files in os.walk(d):
                for f in files:
                    if f.lower().endswith((".ttf", ".otf")):
                        fonts.append(os.path.join(root, f))
    return fonts

all_fonts = find_system_fonts()
print(f"Found {len(all_fonts)} fonts on system")

# Filter to fonts that can render B, D, and suit symbols
usable_fonts = []
for font_path in all_fonts:
    try:
        font = ImageFont.truetype(font_path, 40)
        # Test rendering B and D
        img = Image.new("RGB", (60, 60), "white")
        draw = ImageDraw.Draw(img)
        draw.text((5, 5), "BD♠", font=font, fill="black")
        usable_fonts.append(font_path)
    except Exception:
        continue

print(f"Usable fonts (can render B, D, suit symbols): {len(usable_fonts)}")
for f in usable_fonts[:10]:
    print(f"  {f}")

# Fallback: if fewer than 3 fonts found, use PIL default
if len(usable_fonts) < 3:
    print("WARNING: Few fonts found. Will use PIL default font with size variations.")
    usable_fonts = []  # empty = use default
```

---

### Task 3: Add card rendering function

**Files:**
- Modify: `notebooks/03_german_card_synth.ipynb`

- [ ] **Step 1: Add markdown cell**

```markdown
## 2. Card Rendering

Render a single synthetic card crop: white/cream background, rank letter in upper-left and lower-right corners (mirrored), suit symbol beside the rank.
```

- [ ] **Step 2: Add code cell with render function**

```python
def render_card_crop(
    rank_letter: str,
    suit: str,
    suit_color: tuple,
    font_path: str | None = None,
    font_size: int = 36,
    bg_color: tuple = (255, 255, 255),
    text_color: tuple = (0, 0, 0),
) -> Image.Image:
    """Render a synthetic card crop with rank letter and suit symbol."""
    img = Image.new("RGB", (CARD_WIDTH, CARD_HEIGHT), bg_color)
    draw = ImageDraw.Draw(img)

    # Load font
    if font_path:
        try:
            rank_font = ImageFont.truetype(font_path, font_size)
            suit_font = ImageFont.truetype(font_path, int(font_size * 0.7))
        except Exception:
            rank_font = ImageFont.load_default(size=font_size)
            suit_font = ImageFont.load_default(size=int(font_size * 0.7))
    else:
        rank_font = ImageFont.load_default(size=font_size)
        suit_font = ImageFont.load_default(size=int(font_size * 0.7))

    # Upper-left corner: rank letter
    rank_x, rank_y = 8, 6
    draw.text((rank_x, rank_y), rank_letter, font=rank_font, fill=text_color)

    # Suit symbol below rank letter
    suit_x = rank_x + 4
    suit_y = rank_y + font_size + 2
    draw.text((suit_x, suit_y), suit, font=suit_font, fill=suit_color)

    # Lower-right corner: rank + suit (rotated 180°)
    # Create a small patch, rotate it, paste it
    corner_w, corner_h = 50, font_size + int(font_size * 0.7) + 12
    corner = Image.new("RGB", (corner_w, corner_h), bg_color)
    corner_draw = ImageDraw.Draw(corner)
    corner_draw.text((4, 2), rank_letter, font=rank_font, fill=text_color)
    corner_draw.text((8, font_size + 4), suit, font=suit_font, fill=suit_color)
    corner = corner.rotate(180, expand=False)

    paste_x = CARD_WIDTH - corner_w - 6
    paste_y = CARD_HEIGHT - corner_h - 6
    img.paste(corner, (paste_x, paste_y))

    # Optional: thin border around card edge
    draw.rectangle(
        [(1, 1), (CARD_WIDTH - 2, CARD_HEIGHT - 2)],
        outline=(200, 200, 200),
        width=1,
    )

    return img

# Quick test: render one B card and one D card
fig, axes = plt.subplots(1, 2, figsize=(4, 3))
test_b = render_card_crop("B", "♠", (0, 0, 0))
test_d = render_card_crop("D", "♥", (200, 0, 0))
axes[0].imshow(test_b)
axes[0].set_title("B (Bube)")
axes[0].axis("off")
axes[1].imshow(test_d)
axes[1].set_title("D (Dame)")
axes[1].axis("off")
plt.suptitle("Base renders (before augmentation)")
plt.tight_layout()
plt.show()
```

---

### Task 4: Add augmentation function

**Files:**
- Modify: `notebooks/03_german_card_synth.ipynb`

- [ ] **Step 1: Add markdown cell**

```markdown
## 3. Augmentation Pipeline

Apply randomized transforms to each rendered card to create visual diversity: rotation, brightness/contrast jitter, noise, color tint, and background bleed.
```

- [ ] **Step 2: Add code cell with augmentation function**

```python
def augment_card(img: Image.Image) -> Image.Image:
    """Apply random augmentations to a card crop image."""
    # Random rotation (±15°)
    angle = random.uniform(-15, 15)
    # Use a random background color for rotation fill
    fill_color = tuple(random.randint(200, 255) for _ in range(3))
    img = img.rotate(angle, resample=Image.BILINEAR, expand=False, fillcolor=fill_color)

    # Random brightness (±20%)
    factor = random.uniform(0.8, 1.2)
    img = ImageEnhance.Brightness(img).enhance(factor)

    # Random contrast (±20%)
    factor = random.uniform(0.8, 1.2)
    img = ImageEnhance.Contrast(img).enhance(factor)

    # Random color tint (slight shift)
    if random.random() < 0.3:
        arr = np.array(img, dtype=np.float32)
        tint = np.array([
            random.uniform(-10, 10),
            random.uniform(-10, 10),
            random.uniform(-10, 10),
        ])
        arr = np.clip(arr + tint, 0, 255).astype(np.uint8)
        img = Image.fromarray(arr)

    # Gaussian noise
    if random.random() < 0.5:
        arr = np.array(img, dtype=np.float32)
        sigma = random.uniform(1, 10)
        noise = np.random.normal(0, sigma, arr.shape)
        arr = np.clip(arr + noise, 0, 255).astype(np.uint8)
        img = Image.fromarray(arr)

    # Slight blur (simulating focus variation)
    if random.random() < 0.2:
        img = img.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.5, 1.5)))

    # Random crop/zoom (simulate imperfect YOLO crops)
    if random.random() < 0.3:
        w, h = img.size
        crop_pct = random.uniform(0.05, 0.15)
        left = int(w * random.uniform(0, crop_pct))
        top = int(h * random.uniform(0, crop_pct))
        right = w - int(w * random.uniform(0, crop_pct))
        bottom = h - int(h * random.uniform(0, crop_pct))
        img = img.crop((left, top, right, bottom))
        img = img.resize((w, h), Image.BILINEAR)

    return img

# Show augmentation examples
fig, axes = plt.subplots(2, 5, figsize=(12, 5))
base = render_card_crop("B", "♥", (200, 0, 0))
axes[0][0].imshow(base)
axes[0][0].set_title("Original")
axes[0][0].axis("off")
for i in range(1, 5):
    axes[0][i].imshow(augment_card(base.copy()))
    axes[0][i].set_title(f"Aug {i}")
    axes[0][i].axis("off")

base_d = render_card_crop("D", "♠", (0, 0, 0))
axes[1][0].imshow(base_d)
axes[1][0].set_title("Original")
axes[1][0].axis("off")
for i in range(1, 5):
    axes[1][i].imshow(augment_card(base_d.copy()))
    axes[1][i].set_title(f"Aug {i}")
    axes[1][i].axis("off")

plt.suptitle("Augmentation examples (B top, D bottom)")
plt.tight_layout()
plt.show()
```

---

### Task 5: Add generation loop

**Files:**
- Modify: `notebooks/03_german_card_synth.ipynb`

- [ ] **Step 1: Add markdown cell**

```markdown
## 4. Generate Synthetic Cards

Generate ~500 images per German rank (B→J folder, D→Q folder). Each image uses a random combination of font, suit, colors, and augmentations.
```

- [ ] **Step 2: Add code cell with generation loop**

```python
# Background color palette (white/off-white/cream variations)
BG_COLORS = [
    (255, 255, 255),  # pure white
    (252, 250, 245),  # cream
    (248, 248, 248),  # light grey
    (255, 253, 245),  # warm white
    (245, 245, 250),  # cool white
]

# Text colors for rank letters
TEXT_COLORS = [
    (0, 0, 0),        # black
    (20, 20, 20),     # near-black
    (0, 0, 100),      # dark blue (some decks)
]

# Font sizes to vary
FONT_SIZES = list(range(30, 46, 2))  # 30, 32, 34, ..., 44

def generate_base_designs(rank_letter: str, count: int) -> list[Image.Image]:
    """Generate diverse base card designs for a rank letter."""
    designs = []
    suits_list = list(SUITS.items())

    for i in range(count):
        suit, suit_color = suits_list[i % len(suits_list)]
        bg_color = random.choice(BG_COLORS)
        text_color = random.choice(TEXT_COLORS)
        font_size = random.choice(FONT_SIZES)

        # Pick a random font (or None for default)
        font_path = random.choice(usable_fonts) if usable_fonts else None

        img = render_card_crop(
            rank_letter=rank_letter,
            suit=suit,
            suit_color=suit_color,
            font_path=font_path,
            font_size=font_size,
            bg_color=bg_color,
            text_color=text_color,
        )
        designs.append(img)

    return designs

# Generate for each German rank
for german_letter, target_folder in GERMAN_RANKS.items():
    out_dir = os.path.join(RANK_DIR, target_folder)
    os.makedirs(out_dir, exist_ok=True)

    # Count existing images before generation
    existing = len([f for f in os.listdir(out_dir) if f.endswith((".jpg", ".jpeg", ".png"))])
    print(f"\n{german_letter} → {target_folder}/: {existing} existing images")

    # Generate ~50 base designs, augment each ~10 times = ~500
    num_bases = 50
    augs_per_base = NUM_IMAGES_PER_RANK // num_bases  # 10

    bases = generate_base_designs(german_letter, num_bases)
    generated = 0

    for base_idx, base_img in enumerate(bases):
        for aug_idx in range(augs_per_base):
            augmented = augment_card(base_img.copy())
            filename = f"synth_{german_letter}_{base_idx:03d}_{aug_idx:02d}.jpg"
            augmented.save(os.path.join(out_dir, filename), quality=90)
            generated += 1

    print(f"  Generated {generated} synthetic images → {out_dir}/")
    total_now = len([f for f in os.listdir(out_dir) if f.endswith((".jpg", ".jpeg", ".png"))])
    print(f"  Total in folder: {total_now}")
```

---

### Task 6: Add visual QA and summary

**Files:**
- Modify: `notebooks/03_german_card_synth.ipynb`

- [ ] **Step 1: Add markdown cell**

```markdown
## 5. Visual QA

Display a grid of random synthetic samples from each rank to verify quality.
```

- [ ] **Step 2: Add code cell for visual QA grid**

```python
# Display random samples of generated images
fig, axes = plt.subplots(2, 8, figsize=(20, 6))

for row, (german_letter, target_folder) in enumerate(GERMAN_RANKS.items()):
    out_dir = os.path.join(RANK_DIR, target_folder)
    synth_files = sorted([
        f for f in os.listdir(out_dir)
        if f.startswith(f"synth_{german_letter}")
    ])
    samples = random.sample(synth_files, min(8, len(synth_files)))

    for col, fname in enumerate(samples):
        img = Image.open(os.path.join(out_dir, fname))
        axes[row][col].imshow(img)
        axes[row][col].axis("off")
        if col == 0:
            axes[row][col].set_ylabel(f"{german_letter}→{target_folder}", fontsize=14)

plt.suptitle("Synthetic German Card Samples (B→J top, D→Q bottom)", fontsize=14)
plt.tight_layout()
plt.show()
```

- [ ] **Step 3: Add markdown cell**

```markdown
## 6. Summary

Print final image counts per rank folder to confirm the synthetic data was added correctly.
```

- [ ] **Step 4: Add code cell for summary stats**

```python
# Final summary: image counts per rank folder
print("Rank folder image counts:")
print("-" * 40)
total = 0
for rank in sorted(os.listdir(RANK_DIR)):
    rank_path = os.path.join(RANK_DIR, rank)
    if not os.path.isdir(rank_path):
        continue
    count = len([f for f in os.listdir(rank_path) if f.endswith((".jpg", ".jpeg", ".png"))])
    synth_count = len([f for f in os.listdir(rank_path) if f.startswith("synth_")])
    marker = " ← augmented" if synth_count > 0 else ""
    print(f"  {rank:>3}: {count:5d} images ({synth_count} synthetic){marker}")
    total += 1

print("-" * 40)
print(f"Total rank classes: {total}")
print("\nDone! Run Notebook 02 to train the rank classifier with German card data included.")
```

---

### Task 7: Commit

**Files:**
- `notebooks/03_german_card_synth.ipynb`

- [ ] **Step 1: Stage and commit the new notebook**

```bash
git add notebooks/03_german_card_synth.ipynb
git commit -m "feat: add synthetic German card data generator notebook

Generate B (Bube→J) and D (Dame→Q) synthetic card crops with
PIL rendering and augmentation for rank classifier training."
```
