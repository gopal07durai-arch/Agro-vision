import { useRef, useState, useCallback, useEffect } from 'react';
import { Camera, CameraOff, FlipHorizontal, X, CheckCircle, Loader2, RefreshCw } from 'lucide-react';
import { useLanguage } from '../../i18n';

interface CameraCaptureProps {
  onCapture: (dataUrl: string) => void;
  onClose: () => void;
}

export function CameraCapture({ onCapture, onClose }: CameraCaptureProps) {
  const { t } = useLanguage();
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const [facingMode, setFacingMode] = useState<'environment' | 'user'>('environment');
  const [preview,    setPreview]    = useState<string | null>(null);
  const [isLoading,  setIsLoading]  = useState(true);
  const [error,      setError]      = useState<string | null>(null);
  const [flash,      setFlash]      = useState(false);

  const startCamera = useCallback(async (mode: 'environment' | 'user') => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(t => t.stop());
      streamRef.current = null;
    }

    setIsLoading(true);
    setError(null);
    setPreview(null);

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: mode,
          width: { ideal: 1920 },
          height: { ideal: 1080 },
        },
        audio: false,
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
      }
      setIsLoading(false);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Camera access denied';
      setError(
        msg.includes('denied') || msg.includes('Permission')
          ? t('camera_permission_desc')
          : t('err_unexpected')
      );
      setIsLoading(false);
    }
  }, [t]);

  useEffect(() => {
    startCamera(facingMode);
    return () => {
      streamRef.current?.getTracks().forEach(t => t.stop());
    };
  }, []);

  const handleFlip = () => {
    const next = facingMode === 'environment' ? 'user' : 'environment';
    setFacingMode(next);
    startCamera(next);
  };

  const capturePhoto = () => {
    if (!videoRef.current || !canvasRef.current) return;
    const video = videoRef.current;
    const canvas = canvasRef.current;

    canvas.width = video.videoWidth || 1280;
    canvas.height = video.videoHeight || 720;

    const ctx = canvas.getContext('2d')!;
    if (facingMode === 'user') {
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

    setFlash(true);
    setTimeout(() => setFlash(false), 200);

    const dataUrl = canvas.toDataURL('image/jpeg', 0.92);
    setPreview(dataUrl);
  };

  const handleRetake = () => {
    setPreview(null);
    startCamera(facingMode);
  };

  const handleUse = () => {
    if (preview) onCapture(preview);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black flex flex-col items-center justify-between">

      {/* Hidden canvas for photo capture */}
      <canvas ref={canvasRef} className="hidden" />

      {/* Flash overlay animation */}
      {flash && <div className="absolute inset-0 bg-white z-50 animate-ping" style={{ animationDuration: '200ms' }} />}

      {/* Header bar */}
      <div className="relative z-10 w-full max-w-lg flex items-center justify-between p-4 bg-gradient-to-b from-black/80 to-transparent">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-2xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400">
            <Camera size={18} />
          </div>
          <div>
            <h3 className="font-bold text-white text-sm leading-tight">{t('camera_title')}</h3>
            <p className="text-[11px] text-slate-400 font-medium">{t('camera_position_leaf')}</p>
          </div>

        </div>

        <button
          type="button"
          onClick={onClose}
          className="min-w-[44px] min-h-[44px] flex items-center justify-center rounded-2xl bg-white/10 text-white hover:bg-white/20 transition-colors active:scale-95"
          aria-label={t('close')}
        >
          <X size={20} />
        </button>
      </div>

      {/* Camera View / Preview */}
      <div className="relative flex-1 w-full max-w-lg flex items-center justify-center overflow-hidden">
        {isLoading && (
          <div className="flex flex-col items-center text-white space-y-3">
            <Loader2 size={40} className="animate-spin text-emerald-400" />
            <p className="text-sm font-medium">{t('loading')}</p>
          </div>
        )}

        {error && (
          <div className="p-6 text-center text-white max-w-xs bg-rose-950/80 rounded-3xl border border-rose-500/30 shadow-soft-xl">
            <CameraOff size={48} className="mx-auto text-rose-400 mb-3" />
            <p className="font-bold mb-2 text-sm">{t('camera_permission_title')}</p>
            <p className="text-xs text-rose-200 mb-4">{error}</p>
            <button
              type="button"
              onClick={() => startCamera(facingMode)}
              className="px-5 py-2.5 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 text-white rounded-xl text-xs font-bold shadow-glow-green"
            >
              {t('retry')}
            </button>
          </div>
        )}

        {!error && !preview && (
          <>
            <video
              ref={videoRef}
              playsInline
              muted
              className={`w-full h-full object-cover ${facingMode === 'user' ? 'scale-x-[-1]' : ''}`}
            />
            {/* Viewfinder overlay */}
            <div className="absolute inset-0 flex flex-col items-center justify-center p-6 pointer-events-none">
              <div className="relative w-64 h-64 sm:w-72 sm:h-72 border-2 border-dashed border-emerald-400/80 rounded-3xl overflow-hidden shadow-2xl bg-black/10 backdrop-blur-[1px]">
                <div className="camera-corner top-0 left-0 border-t-4 border-l-4 border-emerald-400 rounded-tl-2xl" />
                <div className="camera-corner top-0 right-0 border-t-4 border-r-4 border-emerald-400 rounded-tr-2xl" />
                <div className="camera-corner bottom-0 left-0 border-b-4 border-l-4 border-emerald-400 rounded-bl-2xl" />
                <div className="camera-corner bottom-0 right-0 border-b-4 border-r-4 border-emerald-400 rounded-br-2xl" />
                <div className="laser-scanner-line" />
              </div>
              <p className="text-white text-xs font-bold mt-4 bg-black/60 backdrop-blur-md px-4 py-2 rounded-full border border-white/20 shadow-soft-sm">
                {t('camera_guide_text')}
              </p>
            </div>
          </>
        )}

        {preview && (
          <img
            src={preview}
            alt="Captured leaf"
            className="w-full h-full object-cover"
          />
        )}
      </div>

      {/* Controls Bar */}
      <div className="relative z-10 w-full max-w-lg p-6 bg-gradient-to-t from-black/95 via-black/60 to-transparent flex items-center justify-around">
        {!preview ? (
          <>
            <button
              type="button"
              onClick={handleFlip}
              className="min-w-[48px] min-h-[48px] p-3 rounded-2xl bg-white/15 text-white hover:bg-white/25 transition-all active:scale-95 flex items-center justify-center"
              title={t('switch_camera')}
              aria-label={t('switch_camera')}
            >
              <FlipHorizontal size={22} />
            </button>

            <button
              type="button"
              onClick={capturePhoto}
              disabled={isLoading}
              className="w-20 h-20 rounded-full border-4 border-white flex items-center justify-center bg-gradient-to-br from-emerald-500 to-green-600 hover:from-emerald-400 hover:to-green-500 active:scale-90 transition-all shadow-glow-green disabled:opacity-50"
              title={t('capture')}
              aria-label={t('capture')}
            >
              <div className="w-14 h-14 rounded-full border-2 border-white bg-emerald-500" />
            </button>

            <div className="w-12 h-12" />
          </>
        ) : (
          <div className="flex items-center justify-center gap-3 w-full">
            <button
              type="button"
              onClick={handleRetake}
              className="flex-1 h-12 px-5 bg-white/20 hover:bg-white/30 text-white rounded-2xl font-bold text-xs sm:text-sm transition-all active:scale-95 flex items-center justify-center gap-2"
            >
              <RefreshCw size={15} />
              <span>{t('retake')}</span>
            </button>

            <button
              type="button"
              onClick={handleUse}
              className="flex-1 h-12 px-5 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 text-white rounded-2xl font-bold text-xs sm:text-sm transition-all shadow-glow-green active:scale-95 flex items-center justify-center gap-2"
            >
              <CheckCircle size={17} />
              <span>{t('use_photo')}</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

