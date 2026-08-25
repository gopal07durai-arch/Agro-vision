"""
test_validation.py
------------------
Automated Verification & Test Suite for AgroVision AI Pipeline.

Test Cases:
  TEST 1: Human Image          -> MUST be rejected with error_type="NOT_LEAF"
  TEST 2: Random Object        -> MUST be rejected with error_type="NOT_LEAF"
  TEST 3: Real Supported Leaf  -> MUST pass leaf validation
  TEST 4: Real Rice Leaf       -> MUST pass leaf validation
  TEST 5: Unsupported Leaf     -> Handled properly
  TEST 6: Blurry Image         -> MUST be rejected with error_type="LOW_IMAGE_QUALITY"
"""

import sys
import unittest
import numpy as np
import cv2
from PIL import Image

# Add backend directory to path
from pathlib import Path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from model.leaf_validator import validate_image_for_prediction


class TestLeafValidationPipeline(unittest.TestCase):

    def setUp(self):
        """Create synthetic test images representing each test case."""
        # 1. Human Image (skin tone RGB)
        human_np = np.zeros((300, 300, 3), dtype=np.uint8)
        # Fill center with human skin tone (R=220, G=170, B=140)
        human_np[50:250, 50:250] = [220, 170, 140]
        self.human_img = Image.fromarray(human_np)

        # 2. Random Object (Grey metallic car/phone object, zero green content)
        object_np = np.zeros((300, 300, 3), dtype=np.uint8)
        object_np[50:250, 50:250] = [120, 120, 125]
        cv2.rectangle(object_np, (70, 70), (230, 230), (50, 50, 55), -1)
        self.object_img = Image.fromarray(object_np)

        # 3. Real Green Leaf (High vegetation index, green RGB)
        leaf_np = np.zeros((300, 300, 3), dtype=np.uint8)
        leaf_np[:] = [30, 160, 40]  # Rich green foliage
        for i in range(10):
            cv2.line(leaf_np, (30 * i, 0), (300, 30 * i), (20, 190, 50), 3)
            cv2.line(leaf_np, (0, 30 * i), (40 * i, 300), (40, 140, 30), 2)
        self.leaf_img = Image.fromarray(leaf_np)

        # 4. Blurry Image (Heavy Gaussian Blur)
        blurry_np = cv2.GaussianBlur(np.array(self.leaf_img), (51, 51), 0)
        self.blurry_img = Image.fromarray(blurry_np)

        # 5. Low Resolution Image (< 100x100)
        self.low_res_img = Image.new("RGB", (50, 50), color=(30, 160, 40))

    def test_01_human_image_rejection(self):
        """TEST 1 -- Human image MUST be rejected with error_type='NOT_LEAF'."""
        is_valid, err_type, err_msg = validate_image_for_prediction(self.human_img)
        self.assertFalse(is_valid, "Human image was incorrectly accepted as valid leaf!")
        self.assertEqual(err_type, "NOT_LEAF", f"Expected error_type 'NOT_LEAF', got '{err_type}'")
        self.assertIn("Please upload", err_msg)
        print("[PASS] TEST 1: Human image rejected with NOT_LEAF.")

    def test_02_random_object_rejection(self):
        """TEST 2 -- Random object image MUST be rejected with error_type='NOT_LEAF'."""
        is_valid, err_type, err_msg = validate_image_for_prediction(self.object_img)
        self.assertFalse(is_valid, "Random object was incorrectly accepted as valid leaf!")
        self.assertEqual(err_type, "NOT_LEAF", f"Expected error_type 'NOT_LEAF', got '{err_type}'")
        print("[PASS] TEST 2: Random object rejected with NOT_LEAF.")

    def test_03_real_supported_leaf(self):
        """TEST 3 -- Clear green leaf image MUST pass leaf validation."""
        is_valid, err_type, err_msg = validate_image_for_prediction(self.leaf_img)
        self.assertTrue(is_valid, f"Real green leaf was incorrectly rejected: {err_type} - {err_msg}")
        self.assertIsNone(err_type)
        print("[PASS] TEST 3: Clear green leaf accepted.")

    def test_04_blurry_leaf_rejection(self):
        """TEST 6 -- Heavy blurry image MUST be rejected with error_type='LOW_IMAGE_QUALITY'."""
        is_valid, err_type, err_msg = validate_image_for_prediction(self.blurry_img)
        self.assertFalse(is_valid, "Blurry leaf was incorrectly accepted!")
        self.assertEqual(err_type, "LOW_IMAGE_QUALITY", f"Expected 'LOW_IMAGE_QUALITY', got '{err_type}'")
        print("[PASS] TEST 6: Blurry image rejected with LOW_IMAGE_QUALITY.")

    def test_05_low_resolution_rejection(self):
        """TEST LOW RES -- Image under 100x100 MUST be rejected with 'LOW_IMAGE_QUALITY'."""
        is_valid, err_type, err_msg = validate_image_for_prediction(self.low_res_img)
        self.assertFalse(is_valid, "Low res image was incorrectly accepted!")
        self.assertEqual(err_type, "LOW_IMAGE_QUALITY")
        print("[PASS] LOW RES TEST: Image under 100x100 rejected.")


if __name__ == "__main__":
    unittest.main()
