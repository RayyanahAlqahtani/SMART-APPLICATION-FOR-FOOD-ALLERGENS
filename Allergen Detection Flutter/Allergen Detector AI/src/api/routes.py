import os
import uuid
import mimetypes
from datetime import datetime
from flask import Blueprint, request, jsonify, send_file
from werkzeug.utils import secure_filename
from src.services.ocr import analyze_image

bp = Blueprint("api", __name__, url_prefix="/api")

# Directory where all scan/product images are stored
SCAN_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'scans')
os.makedirs(SCAN_DIR, exist_ok=True)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_mimetype(filename):
    """Return the correct MIME type for an image file."""
    mime, _ = mimetypes.guess_type(filename)
    return mime or 'image/jpeg'

# ─────────────────────────────────────────────────────────────
#  SCAN  —  POST /api/scan
#  Runs AI analysis AND saves the image.
#  Returns: analysis result + image_path (relative, no base URL)
# ─────────────────────────────────────────────────────────────
@bp.route("/scan", methods=["POST"])
def scan_ingredients():
    if "image" not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "No image selected"}), 400

    if not allowed_file(file.filename):
        return jsonify({"error": "Invalid file type. Allowed: png, jpg, jpeg, gif, webp"}), 400

    try:
        image_bytes = file.read()

        custom_allergens = request.form.get("allergens")
        allergen_list = None
        if custom_allergens:
            allergen_list = [a.strip() for a in custom_allergens.split(",") if a.strip()]

        analysis_result = analyze_image(image_bytes, allergen_list)

        if "error" in analysis_result:
            return jsonify(analysis_result), 500

        # Save image with a structured filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        random_id = str(uuid.uuid4())[:8]
        ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else 'jpg'
        image_filename = f"scan_{timestamp}_{random_id}.{ext}"

        image_path = os.path.join(SCAN_DIR, image_filename)
        with open(image_path, 'wb') as f:
            f.write(image_bytes)

        # Return ONLY the relative filename — the client prepends its own base URL
        analysis_result['image_path'] = f"/api/scan/image/{image_filename}"
        # Keep image_filename for backward compatibility
        analysis_result['image_filename'] = image_filename

        return jsonify(analysis_result), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ─────────────────────────────────────────────────────────────
#  SERVE SCAN IMAGE  —  GET /api/scan/image/<filename>
#  Serves a previously saved scan image by filename.
# ─────────────────────────────────────────────────────────────
@bp.route("/scan/image/<filename>", methods=["GET"])
def get_scan_image(filename):
    try:
        secure_name = secure_filename(filename)
        image_path = os.path.join(SCAN_DIR, secure_name)

        if not os.path.exists(image_path):
            return jsonify({"error": "Image not found"}), 404

        return send_file(image_path, mimetype=get_mimetype(secure_name))

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ─────────────────────────────────────────────────────────────
#  UPLOAD IMAGE  —  POST /api/images/upload
#  Standalone image upload (not tied to a scan).
#  Returns: { "image_path": "/api/images/<filename>" }
# ─────────────────────────────────────────────────────────────
@bp.route("/images/upload", methods=["POST"])
def upload_image():
    if "image" not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "No image selected"}), 400

    if not allowed_file(file.filename):
        return jsonify({"error": "Invalid file type. Allowed: png, jpg, jpeg, gif, webp"}), 400

    try:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        random_id = str(uuid.uuid4())[:8]
        ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else 'jpg'
        image_filename = f"img_{timestamp}_{random_id}.{ext}"

        image_path = os.path.join(SCAN_DIR, image_filename)
        file.save(image_path)

        return jsonify({
            "image_filename": image_filename,
            "image_path": f"/api/images/{image_filename}",
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ─────────────────────────────────────────────────────────────
#  SERVE UPLOADED IMAGE  —  GET /api/images/<filename>
#  Serves any image from the shared scans directory.
# ─────────────────────────────────────────────────────────────
@bp.route("/images/<filename>", methods=["GET"])
def get_image(filename):
    try:
        secure_name = secure_filename(filename)
        image_path = os.path.join(SCAN_DIR, secure_name)

        if not os.path.exists(image_path):
            return jsonify({"error": "Image not found"}), 404

        return send_file(image_path, mimetype=get_mimetype(secure_name))

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ─────────────────────────────────────────────────────────────
#  ALLERGENS LIST  —  GET /api/allergens
# ─────────────────────────────────────────────────────────────
@bp.route("/allergens", methods=["GET"])
def list_allergens():
    return jsonify({"allergens": [
        "Peanuts", "Tree Nuts", "Milk", "Egg", "Wheat", "Soy", "Fish", "Shellfish", "Sesame"
    ]}), 200


# ─────────────────────────────────────────────────────────────
#  HEALTH CHECK  —  GET /api/health
# ─────────────────────────────────────────────────────────────
@bp.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"}), 200
