"""
train_missing_crops.py
----------------------
Training script for missing crop models:
  - Blackgram (5 classes)
  - Sugarcane (3 classes)
  - Turmeric (4 classes)

Architecture:
  - MobileNetV2 pretrained backbone (ImageNet weights)
  - Data Augmentation (rotation, zoom, horizontal flip, brightness)
  - EarlyStopping + ReduceLROnPlateau
  - Saves trained models to backend/model/sub_models/{crop_name}.keras
"""

import os
import sys
import json
import logging
from pathlib import Path
import numpy as np

import tensorflow as tf
from tensorflow.keras import layers, models, callbacks

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger(__name__)

# Paths
BASE_DL = Path(r"C:\Users\gopal\Downloads\Leaf Disease Prediction (DL)")
BACKEND_DIR = Path(__file__).parent
SUB_MODELS_DIR = BACKEND_DIR / "model" / "sub_models"
SUB_MODELS_DIR.mkdir(parents=True, exist_ok=True)

IMAGE_SIZE = 224
BATCH_SIZE = 16
EPOCHS = 15

# Datasets configuration
CROPS_TO_TRAIN = {
    "blackgram": {
        "dataset_path": BASE_DL / "Blackgram" / "Blackgram-20260306T045652Z-3-001" / "Blackgram",
        "output_file": SUB_MODELS_DIR / "blackgram.keras",
        "class_names": ["Anthracnose", "Healthy", "Leaf Crinkle", "Powdery Mildew", "Yellow Mosaic"],
        "folder_map": {
            "anthracnose": "Anthracnose",
            "healthy": "Healthy",
            "leaf crinckle": "Leaf Crinkle",
            "powdery mildew": "Powdery Mildew",
            "yellow mosaic": "Yellow Mosaic",
        }
    },
    "sugarcane": {
        "dataset_path": BASE_DL / "sugarcane" / "Sugarcane_Leaves_Dataset",
        "output_file": SUB_MODELS_DIR / "sugarcane.keras",
        "class_names": ["Healthy", "Red Rot", "Red Rust"],
        "folder_map": {
            "healthy": "Healthy",
            "RedRot": "Red Rot",
            "RedRust": "Red Rust",
        }
    },
    "turmeric": {
        "dataset_path": BASE_DL / "Turmeric" / "Turmeric Plant Disease Augmented Dataset-20260306T050018Z-3-002" / "Turmeric Plant Disease Augmented Dataset",
        "output_file": SUB_MODELS_DIR / "turmeric.keras",
        "class_names": ["Dry Leaf", "Healthy", "Leaf Blotch", "Rhizome Disease"],
        "folder_map": {
            "Dry Leaf": "Dry Leaf",
            "Healthy Leaf": "Healthy",
            "Leaf Blotch": "Leaf Blotch",
            "Rhizome Disease Root": "Rhizome Disease",
            "Rhizome Healthy Root": "Healthy",  # Map healthy root to Healthy
        }
    }
}


def build_mobilenet_model(num_classes: int) -> tf.keras.Model:
    """Build a MobileNetV2 transfer learning model."""
    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3),
        include_top=False,
        weights="imagenet"
    )
    base_model.trainable = False  # Freeze backbone

    inputs = layers.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 3))
    x = tf.keras.applications.mobilenet_v2.preprocess_input(inputs)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(num_classes, activation="softmax")(x)

    model = models.Model(inputs, outputs)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )
    return model, base_model


def train_crop_model(crop_name: str, config: dict):
    dataset_path = config["dataset_path"]
    output_file = config["output_file"]
    class_names = config["class_names"]
    folder_map = config["folder_map"]

    logger.info(f"=== Training model for {crop_name.upper()} ===")
    logger.info(f"Dataset path: {dataset_path}")

    if not dataset_path.exists():
        logger.error(f"Dataset path does not exist: {dataset_path}")
        return

    # Load image paths & labels according to folder_map
    image_paths = []
    labels = []

    for sub_dir in dataset_path.iterdir():
        if sub_dir.is_dir() and sub_dir.name in folder_map:
            target_class_name = folder_map[sub_dir.name]
            class_idx = class_names.index(target_class_name)

            for img_file in sub_dir.rglob("*"):
                if img_file.suffix.lower() in [".jpg", ".jpeg", ".png", ".webp"]:
                    image_paths.append(str(img_file))
                    labels.append(class_idx)

    if not image_paths:
        logger.error(f"No valid images found for {crop_name}!")
        return

    logger.info(f"Loaded {len(image_paths)} images across {len(class_names)} target classes.")

    # Convert to tf.data.Dataset
    def load_and_preprocess(path, label):
        img_bytes = tf.io.read_file(path)
        img = tf.image.decode_image(img_bytes, channels=3, expand_animations=False)
        img = tf.image.resize(img, [IMAGE_SIZE, IMAGE_SIZE])
        img = tf.cast(img, tf.float32)
        return img, label

    dataset = tf.data.Dataset.from_tensor_slices((image_paths, labels))
    dataset = dataset.shuffle(buffer_size=len(image_paths), seed=42)

    # 80/20 train/val split
    val_size = int(len(image_paths) * 0.2)
    val_ds = dataset.take(val_size).map(load_and_preprocess).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)
    train_ds = dataset.skip(val_size).map(load_and_preprocess).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

    # Data augmentation pipeline
    data_augmentation = tf.keras.Sequential([
        layers.RandomFlip("horizontal_and_vertical"),
        layers.RandomRotation(0.15),
        layers.RandomZoom(0.1),
    ])

    model, base_model = build_mobilenet_model(len(class_names))

    # Phase 1: Train classification head
    callbacks_list = [
        callbacks.EarlyStopping(monitor="val_loss", patience=4, restore_best_weights=True),
        callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2, verbose=1)
    ]

    logger.info("Phase 1: Training top classification layers...")
    history1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        callbacks=callbacks_list,
        verbose=1
    )

    # Phase 2: Fine-tuning top layers of MobileNetV2
    logger.info("Phase 2: Fine-tuning MobileNetV2 upper layers...")
    base_model.trainable = True
    # Freeze bottom 100 layers
    for layer in base_model.layers[:100]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )

    history2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=8,
        callbacks=callbacks_list,
        verbose=1
    )

    # Evaluate on val set
    val_loss, val_acc = model.evaluate(val_ds, verbose=0)
    logger.info(f"[{crop_name}] Final Validation Accuracy: {val_acc * 100:.2f}% | Loss: {val_loss:.4f}")

    # Save model
    model.save(str(output_file))
    logger.info(f"[{crop_name}] Successfully saved trained model to {output_file.name}\n")


def main():
    logger.info("Starting training of missing crop sub-models (Blackgram, Sugarcane, Turmeric)...")
    for crop_name, config in CROPS_TO_TRAIN.items():
        train_crop_model(crop_name, config)
    logger.info("All missing crop models trained and saved!")


if __name__ == "__main__":
    main()
