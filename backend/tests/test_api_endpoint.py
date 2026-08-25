import io
import json
import urllib.request
import numpy as np
import cv2
from PIL import Image

def send_image_to_predict(img: Image.Image, filename="test.jpg"):
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    img_bytes = buf.getvalue()

    boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
    body = (
        f'--{boundary}\r\n'
        f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
        'Content-Type: image/jpeg\r\n\r\n'
    ).encode('utf-8') + img_bytes + f'\r\n--{boundary}--\r\n'.encode('utf-8')

    req = urllib.request.Request(
        'http://localhost:8000/api/v1/predict',
        data=body,
        headers={'Content-Type': f'multipart/form-data; boundary={boundary}'}
    )

    try:
        res = urllib.request.urlopen(req)
        return json.loads(res.read()), 200
    except urllib.error.HTTPError as e:
        return json.loads(e.read()), e.code

def test_suite():
    print("=== API END-TO-END VERIFICATION SUITE ===")

    # 1. Valid Green Leaf
    leaf_np = np.zeros((300, 300, 3), dtype=np.uint8)
    leaf_np[:] = [30, 160, 40]
    for i in range(10):
        cv2.line(leaf_np, (30 * i, 0), (300, 30 * i), (20, 190, 50), 3)
    leaf_img = Image.fromarray(leaf_np)
    resp, code = send_image_to_predict(leaf_img, "leaf.jpg")
    print(f"[TEST 1] Real Leaf Image (HTTP {code}):")
    print(" ", json.dumps(resp, indent=2))
    assert resp["success"] == True, "Real leaf should be accepted!"

    # 2. Human Skin Image (Should be rejected with NOT_LEAF)
    human_np = np.zeros((300, 300, 3), dtype=np.uint8)
    human_np[50:250, 50:250] = [220, 170, 140]
    human_img = Image.fromarray(human_np)
    resp, code = send_image_to_predict(human_img, "person.jpg")
    print(f"\n[TEST 2] Human Skin Image (HTTP {code}):")
    print(" ", json.dumps(resp, indent=2))
    assert resp["error_type"] == "NOT_LEAF", "Human image should be rejected as NOT_LEAF!"

    # 3. Random Grey Object Image (Should be rejected with NOT_LEAF)
    obj_np = np.zeros((300, 300, 3), dtype=np.uint8)
    obj_np[50:250, 50:250] = [120, 120, 125]
    obj_img = Image.fromarray(obj_np)
    resp, code = send_image_to_predict(obj_img, "car.jpg")
    print(f"\n[TEST 3] Random Object Image (HTTP {code}):")
    print(" ", json.dumps(resp, indent=2))
    assert resp["error_type"] == "NOT_LEAF", "Random object should be rejected as NOT_LEAF!"

    print("\nALL API VERIFICATION TESTS PASSED SUCCESSFULLY!")

if __name__ == '__main__':
    test_suite()
