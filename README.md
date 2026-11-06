# Image & Text Steganography

A simple Python project that hides information inside images using
**Least Significant Bit (LSB) steganography**. It supports two modes:

1. **Text Steganography** — hide a secret text message inside a cover image.
2. **Binary Image Steganography** — hide a black-and-white (binary) image inside a cover image.

In both cases, the cover image looks visually unchanged to the human eye,
because only the last bit of each pixel value is ever modified.

---

## How It Works

Every pixel in an image is stored as a number from 0–255 (8 bits). LSB
steganography replaces just the **last bit** of that number with a bit of
the secret data:

```
pixel value:        11001010
clear last bit:      & 11111110  ->  11001010
insert secret bit:    |  bit     ->  11001011 (or stays 11001010)
```

Changing only the last bit shifts a pixel's value by at most 1 (e.g. 200
becomes 201), which is far too small a change for the human eye to notice —
but it's enough to encode a full hidden message or image bit by bit.

---

## 1. Text Steganography (`text_steganography.py`)

Hides a secret text message inside a color image.

- Uses a **secret key** to pseudo-randomly scatter the message's bits across
  pixel positions, instead of writing them in a predictable order.
- Only the **blue channel** of each chosen pixel is modified.
- A `#` character is appended to the message as a delimiter, so extraction
  knows where the message ends.
- The same secret key must be used for both hiding and extracting — it's
  what lets the program land on the exact same pixel positions both times.

**Run it:**
```bash
python text_steganography.py
```

**Menu:**
```
1. Hide Message
2. Extract Message
3. Exit
```

**Example — hiding a message:**
```
Enter cover image (e.g., cover.bmp): cover.bmp
Enter secret message: Meet me at 6pm
Enter secret key: 1245
Enter output image (e.g., hide.bmp): hide.bmp
```

**Example — extracting a message:**
```
Enter stego image (e.g., hide.bmp): hide.bmp
Enter secret key: 1245
```
The key must match exactly what was used to hide the message, or the
extracted output will be garbled.

---

## 2. Binary Image Steganography (`image_steganography.py`)

Hides a **binary image** (pure black-and-white, like a logo, silhouette,
or text mask) inside a cover image.

**Important — this only works correctly for binary images.** Each secret
pixel is reduced to a single bit (`black` → 0, `anything else` → 1) before
being hidden, so a grayscale photo with shades of gray will come back as a
black-and-white silhouette, not the original photo. A genuinely
black/white image (only pixel values 0 and 255) hides and recovers with
zero loss.

**Cover image flexibility:**
- The cover can be **color or grayscale** — its original color is preserved
  in the output. For color covers, only the **blue channel** is modified;
  green and red channels (and a grayscale cover's only channel) carry no
  hidden data and stay untouched apart from where the secret bits live.
- The cover **no longer needs to match the secret's exact dimensions** —
  it just needs to have enough total pixels to hold the secret. The
  secret's height and width are stored in the first 32 pixels of the cover
  (as a small "header"), so extraction automatically knows how much of the
  image to read back — you don't need to manually note the secret's size.

**Run it:**
```bash
python image_steganography.py
```

**Menu:**
```
1. Hide Binary Image
2. Extract Binary Image
3. Exit
```

**Example — hiding a binary image:**
```
Enter cover image (e.g., cover.bmp): cover.bmp
Enter binary secret image (e.g., 256secret.bmp): 256secret.bmp
Enter output image name (e.g., hide.bmp): hide.bmp
```

**Example — extracting a binary image:**
```
Enter stego image (e.g., hide.bmp): hide.bmp
Enter extracted image name (e.g., extracted.bmp): extracted.bmp
```

---

## Project Structure

```
image-steganography/
├── images/                     # Place your cover, secret, and output images here
├── image_steganography.py      # Hide/extract a binary image inside a cover image
├── text_steganography.py       # Hide/extract a text message inside a cover image
└── README.md
```

> Image files (`.bmp`) are not included in this repo — add your own cover
> and secret images into the `images/` folder before running either script.

---

## Requirements

- Python 3
- OpenCV (`opencv-python`)
- NumPy

Install dependencies:
```bash
pip install opencv-python numpy
```

---

## Notes & Limitations

- **Text steganography** requires the cover image to have enough pixels to
  hold `(message length + 1) × 8` bits — one bit per pixel for the whole
  message plus its delimiter.
- **Binary image steganography** requires the cover to have at least
  `32 + (secret height × secret width)` pixels.
- Both scripts use **lossless image formats** (`.bmp` is recommended).
  Saving a stego image as a lossy format like `.jpg` will corrupt the
  hidden data, since JPEG compression changes pixel values.
- The secret key in text steganography acts like a password — without the
  exact same key, the message cannot be correctly extracted.
