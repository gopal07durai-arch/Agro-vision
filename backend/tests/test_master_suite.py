"""
test_master_suite.py
--------------------
Automated End-to-End Verification Suite for AgroVision AI Master Prompt.

Tests:
  1. Road image               -> Rejected (422 NOT_LEAF)
  2. Human / Person / Skin    -> Rejected (422 NOT_LEAF)
  3. Building / Architecture  -> Rejected (422 NOT_LEAF)
  4. Car / Vehicle image      -> Rejected (422 NOT_LEAF)
  5. Random Object / Device   -> Rejected (422 NOT_LEAF)
  6. Sky / Blue scene         -> Rejected (422 NOT_LEAF or LOW_IMAGE_QUALITY)
  7. Soil / Dirt texture      -> Rejected (422 NOT_LEAF)
  8. Blurry image             -> Rejected (422 LOW_IMAGE_QUALITY)
  9. Dark image               -> Rejected (422 LOW_IMAGE_QUALITY)
 10. Low resolution (< 60x60) -> Rejected (422 LOW_IMAGE_QUALITY)
 11. Real Supported Leaf      -> Accepted (200 OK, valid_leaf=True, supported_crop=True)
 12. Health Check Endpoint    -> Verified (200 OK, startup_ready=True)
"""

import sys
import io
import json
import urllib.request
import urllib.error
import numpy as np
import cv2
from PIL import Image

# Ensure UTF-8 output on Windows consoles
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

BASE_URL = "http://localhost:8000"


def send_image(img: Image.Image, filename="test.jpg"):
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    img_bytes = buf.getvalue()

    boundary = '----WebKitFormBoundaryMasterTest789'
    body = (
        f'--{boundary}\r\n'
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
        'Content-Type: image/jpeg\r\n\r\n'
    ).encode('utf-8') + img_bytes + f'\r\n--{boundary}--\r\n'.encode('utf-8')

    req = urllib.request.Request(
        f'{BASE_URL}/api/v1/predict',
        data=body,
        headers={'Content-Type': f'multipart/form-data; boundary={boundary}'}
    )

    try:
        res = urllib.request.urlopen(req)
        return json.loads(res.read()), res.status
    except urllib.error.HTTPError as e:
        return json.loads(e.read()), e.code


def run_master_test_suite():
    print("=" * 70)
    print("  AGROVISION AI — MASTER VERIFICATION & REGRESSION SUITE")
    print("=" * 70)

    # ── TEST 0: Health Check ──────────────────────────────────────────────────
    print("\n[TEST 0] Health Check Endpoint:")
    req = urllib.request.Request(f'{BASE_URL}/api/v1/health')
    res = urllib.request.urlopen(req)
    health = json.loads(res.read())
    print(" ", json.dumps(health, indent=2))
    assert health["status"] == "ok", "Health status should be ok!"
    assert health["model_loaded"] == True, "Model should be loaded!"
    assert health["startup_ready"] == True, "Startup should be ready!"
    print("  [PASS] Health check verified.")

    # ── TEST 1: Road / Asphalt (Must be NOT_LEAF) ────────────────────────────
    print("\n[TEST 1] Road Image (Asphalt with white lane markings):")
    road_np = np.zeros((300, 300, 3), dtype=np.uint8)
    road_np[:] = [75, 75, 80] # Dark grey asphalt
    road_np[140:160, :] = [240, 240, 240] # White divider line
    road_img = Image.fromarray(road_np)
    resp, code = send_image(road_img, "road.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "NOT_LEAF", f"Road must be NOT_LEAF, got {resp.get('error_type')}"
    assert resp.get("success") == False
    assert "crop" not in resp or resp.get("valid_leaf") == False
    print("  [PASS] Road rejection verified. (A road image NEVER becomes Wheat!)")

    # ── TEST 2: Human Face / Skin / Hand (Must be NOT_LEAF) ──────────────────
    print("\n[TEST 2] Human Skin / Person Image:")
    human_np = np.zeros((300, 300, 3), dtype=np.uint8)
    human_np[40:260, 40:260] = [220, 170, 140] # Human skin tone RGB
    human_img = Image.fromarray(human_np)
    resp, code = send_image(human_img, "person.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "NOT_LEAF", f"Person must be NOT_LEAF, got {resp.get('error_type')}"
    print("  [PASS] Person/Skin rejection verified.")

    # ── TEST 3: Building / Brick Wall (Must be NOT_LEAF) ─────────────────────
    print("\n[TEST 3] Building / Brick Wall Image:")
    bldg_np = np.zeros((300, 300, 3), dtype=np.uint8)
    bldg_np[:] = [160, 90, 70] # Red brick color RGB
    for r in range(0, 300, 30):
        cv2.line(bldg_np, (0, r), (300, r), (200, 200, 200), 2)
    bldg_img = Image.fromarray(bldg_np)
    resp, code = send_image(bldg_img, "building.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "NOT_LEAF", f"Building must be NOT_LEAF, got {resp.get('error_type')}"
    print("  [PASS] Building rejection verified.")

    # ── TEST 4: Car / Vehicle (Must be NOT_LEAF) ──────────────────────────────
    print("\n[TEST 4] Metallic Car / Vehicle Image:")
    car_np = np.zeros((300, 300, 3), dtype=np.uint8)
    car_np[:] = [30, 30, 180] # Blue metallic car body RGB
    cv2.rectangle(car_np, (60, 60), (240, 180), (20, 20, 20), -1) # Window
    car_img = Image.fromarray(car_np)
    resp, code = send_image(car_img, "car.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "NOT_LEAF", f"Car must be NOT_LEAF, got {resp.get('error_type')}"
    print("  [PASS] Car rejection verified.")

    # ── TEST 5: Laptop / Screen / Tech Device (Must be NOT_LEAF) ─────────────
    print("\n[TEST 5] Laptop / Electronic Device Image:")
    laptop_np = np.zeros((300, 300, 3), dtype=np.uint8)
    laptop_np[:] = [190, 190, 195] # Silver aluminum laptop RGB
    cv2.rectangle(laptop_np, (50, 40), (250, 200), (10, 10, 15), -1) # Black screen
    laptop_img = Image.fromarray(laptop_np)
    resp, code = send_image(laptop_img, "laptop.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "NOT_LEAF", f"Laptop must be NOT_LEAF, got {resp.get('error_type')}"
    print("  [PASS] Laptop/Tech rejection verified.")

    # ── TEST 6: Sky Scene (Must be rejected) ──────────────────────────────────
    print("\n[TEST 6] Sky Scene with Clouds:")
    sky_np = np.zeros((300, 300, 3), dtype=np.uint8)
    sky_np[:] = [100, 180, 240] # Sky blue RGB
    for i in range(5):
        cv2.circle(sky_np, (60 * i + 30, 150), 40, (250, 250, 255), -1) # Clouds
    sky_img = Image.fromarray(sky_np)
    resp, code = send_image(sky_img, "sky.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") in ["NOT_LEAF", "LOW_IMAGE_QUALITY"], f"Sky must be rejected, got {resp.get('error_type')}"
    print("  [PASS] Sky rejection verified.")

    # ── TEST 7: Soil / Dirt Texture (Must be NOT_LEAF) ───────────────────────
    print("\n[TEST 7] Bare Soil / Dirt Image:")
    soil_np = np.zeros((300, 300, 3), dtype=np.uint8)
    soil_np[:] = [90, 60, 40] # Dark brown soil RGB
    for i in range(10):
        cv2.line(soil_np, (0, 30 * i), (300, 30 * i + 15), (70, 45, 30), 2)
    soil_img = Image.fromarray(soil_np)
    resp, code = send_image(soil_img, "soil.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "NOT_LEAF", f"Soil must be NOT_LEAF, got {resp.get('error_type')}"
    print("  [PASS] Soil rejection verified.")

    # ── TEST 8: Blurry Image (Must be LOW_IMAGE_QUALITY) ─────────────────────
    print("\n[TEST 8] Blurry Leaf Image:")
    leaf_np = np.zeros((300, 300, 3), dtype=np.uint8)
    leaf_np[:] = [30, 160, 40]
    blurry_np = cv2.GaussianBlur(leaf_np, (51, 51), 0)
    blurry_img = Image.fromarray(blurry_np)
    resp, code = send_image(blurry_img, "blurry.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "LOW_IMAGE_QUALITY", f"Expected LOW_IMAGE_QUALITY, got {resp.get('error_type')}"
    print("  [PASS] Blurry image rejection verified.")

    # ── TEST 9: Dark Image (Must be LOW_IMAGE_QUALITY) ───────────────────────
    print("\n[TEST 9] Pitch Dark Image:")
    dark_np = np.zeros((300, 300, 3), dtype=np.uint8)
    dark_np[:] = [3, 4, 3] # Almost black RGB
    dark_img = Image.fromarray(dark_np)
    resp, code = send_image(dark_img, "dark.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "LOW_IMAGE_QUALITY", f"Expected LOW_IMAGE_QUALITY, got {resp.get('error_type')}"
    print("  [PASS] Dark image rejection verified.")

    # ── TEST 10: Low Resolution Image (< 60x60) ──────────────────────────────
    print("\n[TEST 10] Low Resolution Image (40x40):")
    lowres_img = Image.new("RGB", (40, 40), color=(30, 160, 40))
    resp, code = send_image(lowres_img, "tiny.jpg")
    print(f"  HTTP {code} -> error_type: {resp.get('error_type')}")
    assert code == 422, f"Expected 422, got {code}"
    assert resp.get("error_type") == "LOW_IMAGE_QUALITY", f"Expected LOW_IMAGE_QUALITY, got {resp.get('error_type')}"
    print("  [PASS] Low resolution rejection verified.")

    # ── TEST 11: Real Green Leaf from Supported Crop (Must be 200 OK) ────────
    print("\n[TEST 11] Real Green Leaf Image:")
    valid_leaf = np.zeros((300, 300, 3), dtype=np.uint8)
    valid_leaf[:] = [35, 165, 45] # Rich plant green RGB
    for i in range(12):
        cv2.line(valid_leaf, (25 * i, 0), (300, 25 * i), (25, 195, 55), 3)
        cv2.line(valid_leaf, (0, 25 * i), (35 * i, 300), (45, 145, 35), 2)
    valid_img = Image.fromarray(valid_leaf)
    resp, code = send_image(valid_img, "valid_leaf.jpg")
    print(f"  HTTP {code} -> success: {resp.get('success')}")
    print("  Response:", json.dumps(resp, indent=2))
    assert code == 200, f"Expected 200 OK, got {code}"
    assert resp.get("success") == True, "Real leaf must succeed!"
    assert resp.get("valid_leaf") == True, "valid_leaf must be True!"
    assert resp.get("supported_crop") == True, "supported_crop must be True!"
    assert resp.get("crop_name") in ["Blackgram", "Cotton", "Eggplant", "Groundnut", "Paddy", "Sugarcane", "Sunflower", "Tomato", "Turmeric", "Wheat"]
    assert "fertilizer" in resp and resp["fertilizer"]["name"] != ""
    print("  [PASS] Real leaf detection & fertilizer recommendation verified.")

    print("\n" + "=" * 70)
    print("  ALL 12 MASTER VERIFICATION TESTS PASSED SUCCESSFULLY! (100% PASS)")
    print("=" * 70)


if __name__ == "__main__":
    run_master_test_suite()
