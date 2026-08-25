"""
train_crop_classifier.py
------------------------
Trains a Stage 1 Crop Classification model (MobileNetV2 backbone)
to identify which crop leaf is present before disease classification.

Crops (10 classes):
  0. Blackgram
  1. Cotton
  2. Eggplant
  3. Groundnut
  4. Paddy
  5. Sugarcane
  6. Sunflower
  7. Tomato
  8. Turmeric
  9. Wheat

Outputs:
  backend/model/sub_models/crop_classifier.keras
"""

import os
import json
import logging
from pathlib import Path
import numpy as np

import tensorflow as tf
from tensorflow.keras import layers, models, callbacks

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger(__name__)

BASE_DL = Path(r"C:\Users\gopal\Downloads\Leaf Disease Prediction (DL)")
BACKEND_DIR = Path(__file__).parent
OUTPUT_FILE = BACKEND_DIR / "model" / "sub_models" / "crop_classifier.keras"

IMAGE_SIZE = 224
BATCH_SIZE = 32
EPOCHS = 12

SUPPORTED_CROPS = [
    "Blackgram", "Cotton", "Eggplant", "Groundnut",
    "Paddy", "Sugarcane", "Sunflower", "Tomato",
    "Turmeric", "Wheat"
]

CROP_DATASETS = {
    "Blackgram": BASE_DL / "Blackgram" / "Blackgram-20260306T045652Z-3-001" / "Blackgram",
    "Cotton": BASE_DL / "cotton" / "cotton disease",
    "Eggplant": BASE_DL / "eggplant" / "Eggplant Disease Recognition Dataset" / "Original Images (Version 02)",
    "Groundnut": BASE_DL / "groundnut" / "Groundnut_Leaf_dataset" / "train",
    "Paddy": BASE_DL / "rice" / "Rice_Leaf_AUG",
    "Sugarcane": BASE_DL / "sugarcane" / "Sugarcane_Leaves_Dataset",
    "Sunflower": BASE_DL / "sunflower" / "sunflower_wheat" / "train",
    "Tomato": BASE_DL / "tomato" / "tomato" / "train",
    "Turmeric": BASE_DL / "Turmeric" / "Turmeric Plant Disease Augmented Dataset-20260306T050018Z-3-002" / "Turmeric Plant Disease Augmented Dataset",
    "Wheat": BASE_DL / "wheat" / "cropDiseaseDataset",
}


def build_crop_classifier() -> tf.keras.Model:
    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3),
        include_top=False,
        weights="imagenet"
    )
    base_model.trainable = False

    inputs = layers.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 3))
    x = tf.keras.applications.mobilenet_v2.preprocess_input(inputs)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(len(SUPPORTED_CROPS), activation="softmax")(x)

    model = models.Model(inputs, outputs)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )
    return model


def main():
    logger.info("Building dataset for Stage 1 Crop Classifier...")

    image_paths = []
    labels = []
    MAX_PER_CROP = 400  # Balanced sample per crop

    for crop_idx, crop_name in enumerate(SUPPORTED_CROPS):
        folder = CROP_DATASETS.get(crop_name)
        if not folder or not folder.exists():
            logger.warning(f"Folder for {crop_name} not found: {folder}")
            continue

        crop_imgs = list(folder.rglob("*.jpg")) + list(folder.rglob("*.jpeg")) + list(folder.rglob("*.png"))
        np.random.seed(42)
        if len(crop_imgs) > MAX_PER_CROP:
            crop_imgs = list(np.random.choice(crop_imgs, MAX_PER_CROP, replace=False))

        logger.info(f"[{crop_name}] Selected {len(crop_imgs)} images.")
        for p in crop_imgs:
            image_paths.append(str(p))
            labels.append(crop_idx)

    logger.info(f"Total dataset: {len(image_paths)} images across {len(SUPPORTED_CROPS)} crops.")

    def load_img(path, label):
        img_bytes = tf.io.read_file(path)
        img = tf.image.decode_image(img_bytes, channels=3, expand_animations=False)
        img = tf.image.resize(img, [IMAGE_SIZE, IMAGE_SIZE])
        img = tf.cast(img, tf.float32)
        return img, label

    dataset = tf.data.Dataset.from_tensor_slices((image_paths, labels))
    dataset = dataset.shuffle(buffer_size=len(image_paths), seed=42)

    val_size = int(len(image_paths) * 0.2)
    val_ds = dataset.take(val_size).map(load_img).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)
    train_ds = dataset.skip(val_size).map(load_img).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

    model = build_crop_classifier()
    callbacks_list = [
        callbacks.EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True),
        callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2, verbose=1)
    ]

    logger.info("Training Crop Classifier model...")
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        callbacks=callbacks_list,
        verbose=1
    )

    val_loss, val_acc = model.evaluate(val_ds, verbose=0)
    logger.info(f"Crop Classifier Validation Accuracy: {val_acc * 100:.2f}% | Loss: {val_loss:.4f}")

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    model.save(str(OUTPUT_FILE))
    logger.info(f"Saved crop classifier to {OUTPUT_FILE.name}")


if __name__ == "__main__":
    main()
