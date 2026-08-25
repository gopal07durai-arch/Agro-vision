import { useRef, useState, useCallback } from 'react';
import { Upload, Camera, Leaf, AlertCircle, X, Sparkles, ImagePlus, ArrowRight, ShieldCheck, RefreshCw } from 'lucide-react';
import { validateImageFile, readFileAsDataUrl } from '../../utils/imageUtils';
import { CameraCapture } from './CameraCapture';
import { useLanguage } from '../../i18n';
import type { TranslationKey } from '../../i18n/types';

interface ImageUploaderProps {
  onImageSelected: (dataUrl: string, isCamera?: boolean) => void;
  disabled?: boolean;
}

const SUPPORTED_CROPS = [
  { nameKey: 'crop_Tomato',    icon: '🍅' },
  { nameKey: 'crop_Paddy',     icon: '🌾' },
  { nameKey: 'crop_Wheat',     icon: '🌾' },
  { nameKey: 'crop_Cotton',    icon: '🌿' },
  { nameKey: 'crop_Sugarcane', icon: '🎋' },
  { nameKey: 'crop_Groundnut', icon: '🥜' },
  { nameKey: 'crop_Sunflower', icon: '🌻' },
  { nameKey: 'crop_Turmeric',  icon: '🟡' },
  { nameKey: 'crop_Blackgram', icon: '🫘' },
  { nameKey: 'crop_Eggplant',  icon: '🍆' },
];

export function ImageUploader({ onImageSelected, disabled }: ImageUploaderProps) {
  const { t } = useLanguage();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [preview,     setPreview]     = useState<string | null>(null);
  const [isDragging,  setIsDragging]  = useState(false);
  const [error,       setError]       = useState<string | null>(null);
  const [showCamera,  setShowCamera]  = useState(false);
  const [isCamera,    setIsCamera]    = useState(false);

  const handleFile = useCallback(async (file: File) => {
    setError(null);
    const errKey = validateImageFile(file);
    if (errKey) {
      setError(t(errKey as TranslationKey) || errKey);
      return;
    }
    try {
      const dataUrl = await readFileAsDataUrl(file);
      setPreview(dataUrl);
      setIsCamera(false);
    } catch {
      setError(t('err_unexpected'));
    }
  }, [t]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  }, [handleFile]);

  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
    e.target.value = '';
  }, [handleFile]);

  const handleCameraCapture = (dataUrl: string) => {
    setShowCamera(false);
    setPreview(dataUrl);
    setIsCamera(true);
    setError(null);
  };

  const clearPreview = () => {
    setPreview(null);
    setError(null);
  };

  if (showCamera) {
    return (
      <CameraCapture
        onCapture={handleCameraCapture}
        onClose={() => setShowCamera(false)}
      />
    );
  }

  return (
    <div className="relative z-10 py-10 sm:py-16 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">

        {/* 1. Hero Section */}
        <div className="text-center mb-10 sm:mb-12 animate-fade-in-up">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 bg-emerald-500/10 dark:bg-emerald-400/10 text-emerald-700 dark:text-emerald-300 px-4 py-1.5 rounded-full text-xs font-bold mb-4 border border-emerald-500/20 backdrop-blur-md shadow-soft-sm">
            <Sparkles size={14} className="text-emerald-500 animate-pulse" />
            <span>{t('hero_badge')}</span>
          </div>

          {/* Main Heading */}
          <h1 className="text-3xl sm:text-5xl md:text-6xl font-black font-display text-slate-900 dark:text-white mb-4 tracking-tight leading-[1.15]">
            Identify Crop Diseases <br className="hidden sm:inline" />
            <span className="bg-gradient-to-r from-emerald-600 to-green-600 bg-clip-text text-transparent">
              Instantly
            </span>
          </h1>

          {/* Subtitle */}
          <p className="text-sm sm:text-base md:text-lg text-slate-600 dark:text-slate-300 max-w-2xl mx-auto leading-relaxed font-medium">
            {t('hero_subtitle_master')}
          </p>
        </div>

        {/* 2. Upload Card or Preview Confirmation Card */}
        {!preview ? (
          <div className="max-w-xl mx-auto animate-fade-in">
            {/* Glassmorphism Upload Container */}
            <div
              onDrop={handleDrop}
              onDragOver={e => { e.preventDefault(); setIsDragging(true); }}
              onDragLeave={() => setIsDragging(false)}
              className={`
                relative rounded-3xl border-2 transition-all duration-300 overflow-hidden
                backdrop-blur-xl bg-white/85 dark:bg-slate-900/85 shadow-soft-xl
                ${isDragging
                  ? 'border-emerald-500 ring-4 ring-emerald-500/20 bg-emerald-50/50 dark:bg-emerald-950/40 scale-[1.01]'
                  : 'border-slate-200/90 dark:border-slate-800 hover:border-emerald-500/60 dark:hover:border-emerald-500/60'
                }
                ${disabled ? 'opacity-50 cursor-not-allowed' : ''}
              `}
            >
              {/* Card Body */}
              <div className="p-8 sm:p-10 text-center flex flex-col items-center">
                {/* Visual Icon */}
                <div className={`
                  w-20 h-20 rounded-3xl flex items-center justify-center mb-5 transition-all duration-300
                  ${isDragging
                    ? 'bg-emerald-500 text-white scale-110 shadow-glow-green'
                    : 'bg-gradient-to-br from-emerald-50 to-green-100 dark:from-emerald-950/70 dark:to-slate-800 text-emerald-600 dark:text-emerald-400 border border-emerald-200/60 dark:border-emerald-800/60 shadow-soft-sm'
                  }
                `}>
                  {isDragging ? <Leaf size={38} /> : <Upload size={36} />}
                </div>

                {/* Card Title */}
                <h3 className="text-xl sm:text-2xl font-extrabold font-display text-slate-900 dark:text-white mb-2">
                  🌿 {t('upload_card_title')}
                </h3>

                {/* Drag & Drop Prompt */}
                <p className="text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">
                  {isDragging ? t('drag_drop_title') : t('upload_card_subtitle')}
                </p>

                <p className="text-xs text-slate-400 dark:text-slate-500 mb-6 font-medium">
                  {t('upload_card_secondary')}
                </p>

                {/* Action Buttons with equal height and weight */}
                <div className="flex flex-col sm:flex-row items-center gap-3 w-full max-w-sm mb-6">
                  {/* Upload Image Button */}
                  <button
                    type="button"
                    onClick={() => !disabled && fileInputRef.current?.click()}
                    disabled={disabled}
                    className="w-full flex-1 h-12 flex items-center justify-center gap-2 px-6 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white rounded-2xl font-bold text-sm shadow-glow-green active:scale-95 transition-all disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
                  >
                    <ImagePlus size={18} />
                    <span>{t('btn_upload_image')}</span>
                  </button>

                  {/* Take Photo Button */}
                  <button
                    type="button"
                    onClick={() => setShowCamera(true)}
                    disabled={disabled}
                    className="w-full flex-1 h-12 flex items-center justify-center gap-2 px-6 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200 border border-slate-200/80 dark:border-slate-700 rounded-2xl font-bold text-sm shadow-soft-sm active:scale-95 transition-all disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
                  >
                    <Camera size={18} className="text-emerald-600 dark:text-emerald-400" />
                    <span>{t('btn_take_photo')}</span>
                  </button>
                </div>

                {/* Supported Formats Pill */}
                <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-slate-100/80 dark:bg-slate-800/80 border border-slate-200/60 dark:border-slate-700/60 text-[11px] font-semibold text-slate-500 dark:text-slate-400">
                  <span>JPG • JPEG • PNG • WEBP (Max 10MB)</span>
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* Preview Confirmation View (Image Ready for Analysis) */
          <div className="max-w-xl mx-auto backdrop-blur-xl bg-white/90 dark:bg-slate-900/90 rounded-3xl shadow-soft-xl border border-slate-200/90 dark:border-slate-800 overflow-hidden animate-fade-in-up">
            <div className="relative aspect-video sm:aspect-[16/10] bg-slate-950 overflow-hidden">
              <img
                src={preview}
                alt="Selected leaf preview"
                className="w-full h-full object-contain"
              />

              <button
                type="button"
                onClick={clearPreview}
                className="absolute top-3 right-3 p-2 rounded-full bg-black/60 hover:bg-rose-600 text-white backdrop-blur-md transition-colors"
                title={t('cancel')}
                aria-label={t('cancel')}
              >
                <X size={16} />
              </button>

              <div className="absolute bottom-3 left-3 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md border border-white/20 text-white text-xs font-semibold flex items-center gap-1.5">
                <Leaf size={12} className="text-emerald-400" />
                <span>{isCamera ? t('preview_captured_photo') : t('preview_uploaded_file')}</span>
              </div>
            </div>

            <div className="p-6">
              <div className="text-center mb-6">
                <div className="inline-flex items-center gap-1.5 text-xs font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/60 px-3 py-1 rounded-full mb-2 border border-emerald-200 dark:border-emerald-800">
                  <ShieldCheck size={14} />
                  <span>{t('preview_leaf_ready')}</span>
                </div>
                <p className="text-xs sm:text-sm text-slate-600 dark:text-slate-400 font-medium">
                  {t('preview_confirm_desc')}
                </p>
              </div>

              <div className="flex flex-col sm:flex-row gap-3">
                <button
                  type="button"
                  onClick={() => onImageSelected(preview, isCamera)}
                  disabled={disabled}
                  className="flex-1 min-h-[48px] py-3 flex items-center justify-center gap-2 px-6 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white rounded-2xl font-bold text-sm transition-all shadow-glow-green active:scale-95 disabled:opacity-50"
                >
                  <Sparkles size={17} className="flex-shrink-0" />
                  <span className="break-words">{t('btn_analyze_leaf')}</span>
                  <ArrowRight size={16} className="flex-shrink-0" />
                </button>

                <button
                  type="button"
                  onClick={clearPreview}
                  className="min-h-[48px] py-3 px-6 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-2xl font-bold text-sm transition-all active:scale-95 flex items-center justify-center gap-2"
                >
                  <RefreshCw size={15} className="flex-shrink-0" />
                  <span className="break-words">{t('btn_replace_image')}</span>
                </button>
              </div>
            </div>

          </div>
        )}

        {/* Error Alert */}
        {error && (
          <div className="max-w-xl mx-auto mt-4 flex items-center gap-3 bg-rose-50/90 dark:bg-rose-950/60 border border-rose-200 dark:border-rose-800 rounded-2xl p-4 text-rose-700 dark:text-rose-300 animate-fade-in backdrop-blur-md">
            <AlertCircle size={18} className="flex-shrink-0 text-rose-500" />
            <p className="text-xs sm:text-sm font-semibold">{error}</p>
          </div>
        )}

        {/* Hidden File Input */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={handleInputChange}
          className="hidden"
          disabled={disabled}
        />

        {/* 3. Supported Crops Section */}
        <div className="mt-12 sm:mt-16 text-center animate-fade-in-up">
          <p className="text-xs font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-4">
            {t('supported_crops_label')}
          </p>

          <div className="flex flex-wrap justify-center gap-2 max-w-3xl mx-auto">
            {SUPPORTED_CROPS.map(crop => (
              <span
                key={crop.nameKey}
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border border-slate-200/80 dark:border-slate-800 rounded-full text-xs font-semibold text-slate-700 dark:text-slate-300 shadow-soft-sm hover:border-emerald-500 dark:hover:border-emerald-500 transition-colors"
              >
                <span>{crop.icon}</span>
                <span>{t(crop.nameKey as TranslationKey)}</span>
              </span>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}

