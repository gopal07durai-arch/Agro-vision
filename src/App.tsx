import { useState, useEffect, useCallback } from 'react';
import { Header } from './components/layout/Header';
import { AgricultureBackground } from './components/layout/AgricultureBackground';
import { AboutModal } from './components/layout/AboutModal';
import { ImageUploader } from './components/upload/ImageUploader';
import { LeafValidationError } from './components/upload/LeafValidationError';
import { AnalyzingLoader } from './components/prediction/AnalyzingLoader';
import { PredictionPage } from './components/prediction/PredictionPage';
import { HistoryPage } from './components/history/HistoryPage';
import { Chat } from './components/Chat';
import { usePrediction } from './hooks/usePrediction';
import { checkBackendHealth } from './services/predictionService';
import { useLanguage } from './i18n';
import type { TranslationKey } from './i18n/types';
import { Sprout } from 'lucide-react';

// ── Session ID ─────────────────────────────────────────────────
function getSessionId(): string {
  const key = 'agrovision-session-v1';
  const stored = localStorage.getItem(key);
  if (stored) return stored;
  const id = `session-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  localStorage.setItem(key, id);
  return id;
}

// ── PDF Export ─────────────────────────────────────────────────
function generatePDF(
  prediction: { crop: string; disease: string; crop_confidence: number; disease_confidence: number; severity: string },
  diseaseInfo: { overview?: string; biofertilizer?: string; dosage?: string; recoveryTime?: string } | null,
  imageDataUrl: string,
  t: (key: TranslationKey) => string,
  translatedCrop: string,
  translatedDisease: string,
  translatedSeverity: string
) {
  const printWindow = window.open('', '_blank');
  if (!printWindow) return;

  const disclaimerText = t('pdf_disclaimer');

  const content = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>${t('pdf_report_title')} — ${translatedCrop} ${translatedDisease}</title>
      <style>
        body { font-family: 'Inter', system-ui, sans-serif; max-width: 700px; margin: 40px auto; color: #0f172a; line-height: 1.5; }
        .header { background: linear-gradient(135deg, #064e3b, #059669); color: white; padding: 24px; border-radius: 16px; margin-bottom: 24px; }
        .header h1 { margin: 0 0 4px; font-size: 22px; font-weight: 800; }
        .header p  { margin: 0; opacity: 0.85; font-size: 13px; }
        img { width: 100%; max-height: 280px; object-fit: cover; border-radius: 16px; margin-bottom: 20px; border: 1px solid #e2e8f0; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }
        .card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px; }
        .label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; margin-bottom: 4px; }
        .value { font-size: 16px; font-weight: 800; color: #0f172a; }
        .section { margin-bottom: 20px; background: #ffffff; border: 1px solid #e2e8f0; padding: 16px; border-radius: 12px; }
        .section h3 { font-size: 14px; font-weight: 800; color: #059669; border-bottom: 2px solid #d1fae5; padding-bottom: 6px; margin-top: 0; margin-bottom: 10px; }
        p { margin: 0 0 8px; font-size: 13px; color: #334155; }
        .footer { margin-top: 32px; padding: 16px; background: #f8fafc; border-radius: 12px; font-size: 12px; color: #64748b; text-align: center; }
        @media print { body { margin: 20px; } }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>🌿 ${t('pdf_report_title')}</h1>
        <p>${t('pdf_generated_on')} ${new Date().toLocaleDateString(undefined, { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}</p>
      </div>

      <img src="${imageDataUrl}" alt="Analyzed leaf" />

      <div class="grid">
        <div class="card">
          <div class="label">${t('crop_detected')}</div>
          <div class="value">${translatedCrop}</div>
        </div>
        <div class="card">
          <div class="label">${t('disease_identified')}</div>
          <div class="value">${translatedDisease}</div>
        </div>
        <div class="card">
          <div class="label">${t('crop_confidence')}</div>
          <div class="value">${prediction.crop_confidence ? prediction.crop_confidence.toFixed(1) + '%' : 'N/A'}</div>
        </div>
        <div class="card">
          <div class="label">${t('disease_confidence')}</div>
          <div class="value">${prediction.disease_confidence ? prediction.disease_confidence.toFixed(1) + '%' : 'N/A'}</div>
        </div>
        <div class="card">
          <div class="label">${t('severity_level')}</div>
          <div class="value">${translatedSeverity}</div>
        </div>
      </div>

      ${diseaseInfo ? `
      <div class="section">
        <h3>📋 ${t('disease_overview')}</h3>
        <p>${diseaseInfo.overview ?? ''}</p>
      </div>
      <div class="section">
        <h3>🧪 ${t('biofertilizer')}</h3>
        <p><strong>${diseaseInfo.biofertilizer ?? 'N/A'}</strong><br>
        ${t('dosage')}: ${diseaseInfo.dosage ?? 'N/A'}</p>
      </div>
      <div class="section">
        <h3>⏱️ ${t('recovery_time')}</h3>
        <p>${diseaseInfo.recoveryTime ?? 'N/A'}</p>
      </div>
      ` : ''}

      ${disclaimerText ? `<div class="footer">${disclaimerText}</div>` : ''}
    </body>
    </html>
  `;

  printWindow.document.write(content);
  printWindow.document.close();
  setTimeout(() => printWindow.print(), 500);
}

// ── View types ─────────────────────────────────────────────────
type View = 'splash' | 'upload' | 'analyzing' | 'prediction' | 'chat' | 'history';

// ── Splash Screen ──────────────────────────────────────────────
function SplashScreen() {
  const { t } = useLanguage();
  return (
    <div className="fixed inset-0 z-[100] splash-gradient flex flex-col items-center justify-center">
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-72 h-72 bg-emerald-500/10 rounded-full animate-ping-slow" />
        <div className="absolute bottom-1/3 right-1/4 w-56 h-56 bg-teal-500/10 rounded-full animate-ping-slow delay-700" />
      </div>

      <div className="relative z-10 text-center px-4">
        <div className="mb-6">
          <div className="w-20 h-20 bg-gradient-to-br from-emerald-400 to-green-600 rounded-3xl flex items-center justify-center mx-auto shadow-glow-green animate-bounce-in">
            <Sprout size={42} className="text-white" />
          </div>
        </div>

        <h1 className="text-3xl sm:text-4xl font-black font-display text-white mb-2 tracking-tight">
          AgroVision <span className="text-emerald-300">AI</span>
        </h1>
        <p className="text-emerald-100/80 text-xs sm:text-sm font-medium mb-8">
          {t('app_subtitle')}
        </p>

        <div className="w-48 h-1.5 bg-white/10 rounded-full mx-auto overflow-hidden">
          <div className="h-full bg-gradient-to-r from-emerald-400 to-green-400 rounded-full animate-[progressBar_2s_ease-in-out_forwards]" />
        </div>

      </div>
    </div>
  );
}

// ── Main App ───────────────────────────────────────────────────
export default function App() {
  const { t, languageName, translateCrop, translateDisease, translateSeverity } = useLanguage();
  const [view, setView] = useState<View>('splash');
  const [darkMode, setDarkMode] = useState(() =>
    localStorage.getItem('agrovision-dark') === 'true' ||
    window.matchMedia('(prefers-color-scheme: dark)').matches
  );
  const [imageDataUrl, setImageDataUrl] = useState<string | null>(null);
  const [sessionId] = useState(getSessionId);
  const [backendOnline, setBackendOnline] = useState<boolean | undefined>(undefined);
  const [aboutOpen, setAboutOpen] = useState(false);

  // Splash → upload after 2s
  useEffect(() => {
    const timer = setTimeout(() => setView('upload'), 2000);
    return () => clearTimeout(timer);
  }, []);

  // Sync dark mode
  useEffect(() => {
    document.documentElement.classList.toggle('dark', darkMode);
    localStorage.setItem('agrovision-dark', String(darkMode));
  }, [darkMode]);

  // Check backend health on mount
  useEffect(() => {
    checkBackendHealth().then(setBackendOnline);
  }, []);

  const { state: predState, analyze, reset } = usePrediction(sessionId);

  // Watch prediction state
  useEffect(() => {
    if (predState.step === 'complete') setView('prediction');
    if (predState.step === 'error') setView('upload');
  }, [predState.step]);


  const handleImageSelected = useCallback(async (dataUrl: string, isCamera = false) => {
    setImageDataUrl(dataUrl);
    setView('analyzing');
    await analyze(dataUrl, isCamera, languageName);
  }, [analyze, languageName]);

  const handleReset = useCallback(() => {
    reset();
    setImageDataUrl(null);
    setView('upload');
  }, [reset]);

  const handleDownload = useCallback(() => {
    if (predState.prediction && imageDataUrl) {
      const c = translateCrop(predState.prediction.crop);
      const d = translateDisease(predState.prediction.disease);
      const s = translateSeverity(predState.prediction.severity);
      generatePDF(predState.prediction, predState.diseaseInfo, imageDataUrl, t, c, d, s);
    }
  }, [predState.prediction, predState.diseaseInfo, imageDataUrl, t, translateCrop, translateDisease, translateSeverity]);

  const getHeaderSubtitle = (): string | undefined => {
    switch (view) {
      case 'analyzing': return t('analyzing_title') + '...';
      case 'prediction': return t('analysis_complete');
      case 'history': return t('history_title');
      case 'chat': return predState.prediction
        ? `${translateCrop(predState.prediction.crop)} — ${t('chat_assistant')}`
        : t('chat_assistant');
      default: return undefined;
    }
  };

  return (
    <>
      {/* Splash Screen */}
      {view === 'splash' && <SplashScreen />}

      {/* Main App Container */}
      <div className={`relative min-h-screen flex flex-col transition-colors duration-300 ${view === 'splash' ? 'invisible' : 'visible'}`}>
        
        {/* Subtle Agriculture Animated Background */}
        <AgricultureBackground />

        {/* About AgroVision AI Modal Dialog */}
        <AboutModal
          isOpen={aboutOpen}
          onClose={() => setAboutOpen(false)}
        />

        {/* Sticky Navbar */}
        {view !== 'analyzing' && (
          <Header
            darkMode={darkMode}
            onToggleDarkMode={() => setDarkMode(d => !d)}
            showBack={view === 'prediction' || view === 'chat' || view === 'history'}
            onBack={
              view === 'chat' ? () => setView('prediction') :
                view === 'history' ? () => setView('upload') :
                  handleReset
            }
            onHome={handleReset}
            onScan={handleReset}
            onHistory={() => setView('history')}
            onAbout={() => setAboutOpen(true)}
            currentView={view}
            subtitle={getHeaderSubtitle()}
            backendOnline={backendOnline}
          />
        )}

        {/* Main Content Area */}
        <main className="flex-1">

          {/* Upload View */}
          {view === 'upload' && (
            <div>
              {predState.error ? (
                <div className="max-w-lg mx-auto px-4 pt-6 animate-fade-in">
                  <LeafValidationError
                    reason={t(predState.error as TranslationKey) || predState.error}
                    quality={predState.errorType ?? 'NOT_LEAF'}
                    onRetry={handleReset}
                  />
                </div>
              ) : (
                <ImageUploader onImageSelected={handleImageSelected} />
              )}
            </div>
          )}

          {/* Analyzing View */}
          {view === 'analyzing' && (
            <AnalyzingLoader
              step={predState.step as 'compressing' | 'quality_check' | 'validating' | 'predicting' | 'explaining'}
              progress={predState.progress}
              statusMessage={predState.statusMessage}
              imageDataUrl={imageDataUrl}
            />
          )}

          {/* Prediction Results Dashboard */}
          {view === 'prediction' && predState.prediction && (
            <PredictionPage
              prediction={predState.prediction}
              fertilizers={predState.fertilizers}
              diseaseInfo={predState.diseaseInfo}
              imageDataUrl={imageDataUrl!}
              sessionId={sessionId}
              onStartChat={() => setView('chat')}
              onReset={handleReset}
              onDownload={handleDownload}
            />
          )}

          {/* AI Chat View */}
          {view === 'chat' && predState.prediction && (
            <div className="flex flex-col" style={{ height: 'calc(100vh - 64px)' }}>
              <Chat prediction={predState.prediction} />
            </div>
          )}

          {/* Scan History View */}
          {view === 'history' && (
            <HistoryPage
              sessionId={sessionId}
              onBack={() => setView('upload')}
            />
          )}
        </main>
      </div>
    </>
  );
}

