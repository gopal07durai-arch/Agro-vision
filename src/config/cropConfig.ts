/**
 * cropConfig.ts
 * Centralized Configuration for AgroVision AI Supported Crops & Model Specs.
 */

export interface CropSpec {
  displayName: string;
  aliases: string[];
  diseases: string[];
}

export const SUPPORTED_CROPS: Record<string, CropSpec> = {
  Blackgram: {
    displayName: 'Blackgram',
    aliases: ['blackgram', 'urad', 'minumulu', 'uzhunnu'],
    diseases: ['Anthracnose', 'Healthy', 'Leaf Crinkle', 'Powdery Mildew', 'Yellow Mosaic'],
  },
  Cotton: {
    displayName: 'Cotton',
    aliases: ['cotton', 'kapas', 'patti'],
    diseases: ['Aphids', 'Army Worm', 'Bacterial Blight', 'Healthy', 'Powdery Mildew', 'Target Spot'],
  },
  Eggplant: {
    displayName: 'Eggplant (Brinjal)',
    aliases: ['eggplant', 'brinjal', 'baingan', 'vankaya', 'kathirikai'],
    diseases: ['Healthy', 'Insect Pest', 'Leaf Spot', 'Mosaic Virus', 'Small Leaf', 'White Mold', 'Wilt Disease'],
  },
  Groundnut: {
    displayName: 'Groundnut',
    aliases: ['groundnut', 'peanut', 'moongphali', 'verukadalai'],
    diseases: ['Healthy', 'Late Leaf Spot', 'Leaf Spot', 'Nutrition Deficiency', 'Rust'],
  },
  Paddy: {
    displayName: 'Paddy (Rice)',
    aliases: ['paddy', 'rice', 'chawal', 'dhan', 'arisi'],
    diseases: ['Brown Spot', 'Healthy', 'Leaf Blast', 'Leaf Blight', 'Leaf Scald', 'Sheath Blight'],
  },
  Sugarcane: {
    displayName: 'Sugarcane',
    aliases: ['sugarcane', 'ganna', 'karumbu'],
    diseases: ['Healthy', 'Red Rot', 'Red Rust'],
  },
  Sunflower: {
    displayName: 'Sunflower',
    aliases: ['sunflower', 'surajmukhi'],
    diseases: ['Alternaria Leaf Spot', 'Downy Mildew', 'Healthy', 'Powdery Mildew', 'Rhizopus Head Rot', 'Rust', 'Sclerotinia'],
  },
  Tomato: {
    displayName: 'Tomato',
    aliases: ['tomato', 'tamatar', 'thakkali'],
    diseases: ['Bacterial Spot', 'Early Blight', 'Healthy', 'Late Blight', 'Leaf Mold', 'Mosaic Virus', 'Septoria Leaf Spot', 'Spider Mites', 'Target Spot', 'Yellow Leaf Curl Virus'],
  },
  Turmeric: {
    displayName: 'Turmeric',
    aliases: ['turmeric', 'haldi', 'manjal'],
    diseases: ['Dry Leaf', 'Healthy', 'Leaf Blotch', 'Rhizome Disease'],
  },
  Wheat: {
    displayName: 'Wheat',
    aliases: ['wheat', 'gehun', 'gothumai'],
    diseases: ['Crown Root Rot', 'Healthy', 'Leaf Rust', 'Loose Smut'],
  },
};

export function isSupportedCrop(cropName: string): boolean {
  if (!cropName) return false;
  const normalized = cropName.trim().toLowerCase();
  return Object.values(SUPPORTED_CROPS).some(spec =>
    spec.displayName.toLowerCase() === normalized ||
    spec.aliases.some(alias => alias.toLowerCase() === normalized)
  );
}
