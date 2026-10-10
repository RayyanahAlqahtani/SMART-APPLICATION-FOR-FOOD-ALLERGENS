"""
Advanced Image Preprocessing Pipeline for OCR.
Uses OpenCV for noise reduction, binarization, deskewing, and contrast enhancement.
"""
import cv2
import numpy as np
from PIL import Image
import io


def pil_to_cv2(pil_image):
    """Convert PIL Image to OpenCV BGR numpy array."""
    rgb = np.array(pil_image.convert("RGB"))
    return cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)


def cv2_to_pil(cv2_image):
    """Convert OpenCV BGR/Grayscale numpy array to PIL Image."""
    if len(cv2_image.shape) == 2:
        return Image.fromarray(cv2_image)
    return Image.fromarray(cv2.cvtColor(cv2_image, cv2.COLOR_BGR2RGB))


def bytes_to_cv2(image_bytes):
    """Convert raw image bytes to OpenCV numpy array."""
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Could not decode the image bytes.")
    return img


def resize_for_ocr(img, target_width=1200):
    """Resize keeping aspect ratio. Larger images give better OCR results."""
    h, w = img.shape[:2]
    if w < target_width:
        scale = target_width / w
        new_w = target_width
        new_h = int(h * scale)
        img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
    return img


def deskew(img):
    """Correct slight rotation/skew in the image."""
    gray = img if len(img.shape) == 2 else cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    coords = np.column_stack(np.where(gray > 0))
    if coords.shape[0] < 50:
        return img
    angle = cv2.minAreaRect(coords)[-1]
    if angle < -45:
        angle = -(90 + angle)
    else:
        angle = -angle
    if abs(angle) < 0.5:
        return img
    (h, w) = img.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    rotated = cv2.warpAffine(
        img, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE
    )
    return rotated


def preprocess_for_ocr(image_bytes):
    """
    Full preprocessing pipeline that dramatically improves OCR accuracy:
      1. Decode & resize
      2. Convert to grayscale
      3. Denoise (Non-Local Means)
      4. CLAHE contrast enhancement
      5. Adaptive thresholding (Gaussian)
      6. Morphological cleanup (remove small noise dots)
      7. Deskew
    Returns a PIL Image ready for Tesseract.
    """
    img = bytes_to_cv2(image_bytes)

    # 1. Resize small images
    img = resize_for_ocr(img, target_width=1200)

    # 2. Grayscale
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 3. Denoise
    denoised = cv2.fastNlMeansDenoising(gray, h=12, templateWindowSize=7, searchWindowSize=21)

    # 4. Contrast enhancement (CLAHE)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(denoised)

    # 5. Adaptive threshold (much better than global for uneven lighting / packaging)
    binary = cv2.adaptiveThreshold(
        enhanced, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 10
    )

    # 6. Morphological cleanup – remove tiny noise specks
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
    cleaned = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel, iterations=1)

    # 7. Deskew
    final = deskew(cleaned)

    return cv2_to_pil(final)


def get_preprocessing_stages(image_bytes):
    """
    Return a dict of intermediate preprocessing stages for visualization / debugging.
    Useful in the Jupyter notebook.
    """
    stages = {}
    img = bytes_to_cv2(image_bytes)
    stages["original"] = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    img = resize_for_ocr(img, target_width=1200)
    stages["resized"] = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    stages["grayscale"] = gray

    denoised = cv2.fastNlMeansDenoising(gray, h=12, templateWindowSize=7, searchWindowSize=21)
    stages["denoised"] = denoised

    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(denoised)
    stages["clahe_enhanced"] = enhanced

    binary = cv2.adaptiveThreshold(
        enhanced, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 10
    )
    stages["adaptive_threshold"] = binary

    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
    cleaned = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel, iterations=1)
    stages["morphological_cleanup"] = cleaned

    final = deskew(cleaned)
    stages["deskewed_final"] = final

    return stages
