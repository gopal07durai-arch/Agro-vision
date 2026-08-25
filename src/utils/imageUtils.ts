/**
 * imageUtils.ts
 * Utilities for image compression, quality assessment, and upload validation.
 */

const MAX_DIMENSION = 900;        // px — slightly larger for better accuracy
const JPEG_QUALITY_FILE   = 0.88; // upload quality
const JPEG_QUALITY_CAMERA = 0.92; // camera captures need higher quality

/**
 * Compress an image data URL.
 * @param dataUrl  Source data URL
 * @param forCamera  Use higher quality for camera captures
 */
export async function compressImage(
  dataUrl: string,
  forCamera = false
): Promise<string> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      let { width, height } = img;

      if (width > MAX_DIMENSION || height > MAX_DIMENSION) {
        if (width > height) {
          height = Math.round((height * MAX_DIMENSION) / width);
          width = MAX_DIMENSION;
        } else {
          width = Math.round((width * MAX_DIMENSION) / height);
          height = MAX_DIMENSION;
        }
      }

      canvas.width  = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d')!;
      ctx.drawImage(img, 0, 0, width, height);
      const quality = forCamera ? JPEG_QUALITY_CAMERA : JPEG_QUALITY_FILE;
      resolve(canvas.toDataURL('image/jpeg', quality));
    };
    img.onerror = reject;
    img.src = dataUrl;
  });
}

/**
 * Convert a base64 data URL to a Blob (for multipart form upload).
 */
export function dataUrlToBlob(dataUrl: string): Blob {
  const [header, data] = dataUrl.split(',');
  const mime = header.match(/:(.*?);/)?.[1] ?? 'image/jpeg';
  const binary = atob(data);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return new Blob([bytes], { type: mime });
}

/**
 * Validate file before loading (type + size).
 * Returns null if valid, error string if invalid.
 */
export function validateImageFile(file: File): string | null {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
  if (!allowedTypes.includes(file.type)) {
    return 'Please upload a JPEG, PNG, or WebP image.';
  }
  if (file.size > 10 * 1024 * 1024) {
    return 'Image size must be less than 10MB.';
  }
  return null;
}

/**
 * Read a File as a base64 data URL.
 */
export function readFileAsDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload  = () => resolve(reader.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

/**
 * Assess image quality (brightness, blur estimate, resolution).
 * Uses a canvas pixel analysis — runs in < 50ms on typical images.
 */
export interface ImageQualityReport {
  isBlurry: boolean;
  isDark: boolean;
  isLowRes: boolean;
  brightness: number;   // 0–255
  score: number;        // 0–100 overall quality
}

export async function assessImageQuality(
  dataUrl: string
): Promise<ImageQualityReport> {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      const W = img.naturalWidth;
      const H = img.naturalHeight;

      // Resolution check
      const isLowRes = W < 100 || H < 100;

      // Sample at 64×64 for performance
      const SAMPLE = 64;
      const canvas = document.createElement('canvas');
      canvas.width  = SAMPLE;
      canvas.height = SAMPLE;
      const ctx = canvas.getContext('2d')!;
      ctx.drawImage(img, 0, 0, SAMPLE, SAMPLE);
      const { data } = ctx.getImageData(0, 0, SAMPLE, SAMPLE);

      let brightness = 0;
      let edgeSum    = 0;

      for (let i = 0; i < data.length; i += 4) {
        const r = data[i], g = data[i + 1], b = data[i + 2];
        const lum = 0.299 * r + 0.587 * g + 0.114 * b;
        brightness += lum;

        // Approximate edge magnitude (horizontal difference)
        if (i + 4 < data.length) {
          const nr = data[i + 4], ng = data[i + 5], nb = data[i + 6];
          const nextLum = 0.299 * nr + 0.587 * ng + 0.114 * nb;
          edgeSum += Math.abs(lum - nextLum);
        }
      }

      const pixelCount = SAMPLE * SAMPLE;
      const avgBrightness = brightness / pixelCount;        // 0–255
      const avgEdge       = edgeSum / pixelCount;           // 0–255

      const isDark   = avgBrightness < 20;
      // Low average edge contrast → likely blurry
      const isBlurry = avgEdge < 2.5 && !isLowRes;

      // Quality score
      let score = 100;
      if (isLowRes)  score -= 40;
      if (isDark)    score -= 30;
      if (isBlurry)  score -= 25;
      score = Math.max(0, Math.min(100, score));

      resolve({ isBlurry, isDark, isLowRes, brightness: avgBrightness, score });
    };
    img.onerror = () =>
      resolve({ isBlurry: false, isDark: false, isLowRes: true, brightness: 0, score: 0 });
    img.src = dataUrl;
  });
}
