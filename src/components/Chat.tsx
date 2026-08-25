import { useState, useEffect, useRef } from 'react';
import { useGeminiChat } from '../hooks/useGeminiChat';
import type { PredictionResult } from '../types';
import { getCropIcon, getDiseaseIcon } from '../utils/diseaseUtils';
import { Send, Sparkles } from 'lucide-react';
import { useLanguage } from '../i18n';

interface ChatProps {
  prediction: PredictionResult;
}

function renderContent(text: string) {
  const lines = text.split('\n');
  return lines.map((line, i) => {
    const boldified = line.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    const isBullet = line.trim().startsWith('•') || line.trim().startsWith('-') || line.trim().startsWith('*');
    if (isBullet) {
      return (
        <li
          key={i}
          className="ml-4 text-xs sm:text-sm leading-relaxed"
          dangerouslySetInnerHTML={{ __html: boldified.replace(/^[•\-\*]\s*/, '') }}
        />
      );
    }
    return line.trim() ? (
      <p key={i} className="text-xs sm:text-sm leading-relaxed" dangerouslySetInnerHTML={{ __html: boldified }} />
    ) : (
      <br key={i} />
    );
  });
}

export function Chat({ prediction }: ChatProps) {
  const { t, languageName, translateCrop, translateDisease } = useLanguage();

  const { messages, isLoading, sendMessage, suggestedQuestions } = useGeminiChat({
    crop: prediction.crop,
    disease: prediction.disease,
    languageName,
    t,
    translateCrop,
    translateDisease,
  });

  const [text, setText] = useState('');
  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim() || isLoading) return;
    sendMessage(text.trim());
    setText('');
  };

  const handleSuggestion = (q: string) => {
    if (!isLoading) sendMessage(q);
  };

  const translatedCrop = translateCrop(prediction.crop);
  const translatedDisease = translateDisease(prediction.disease);
  const chips = suggestedQuestions.slice(0, 4);
  const confValue = prediction.disease_confidence || prediction.crop_confidence || 0;

  return (
    <div className="flex flex-col h-full bg-slate-50/50 dark:bg-slate-950/50">

      {/* Context banner */}
      <div className="bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl border-b border-slate-200/90 dark:border-slate-800 px-4 sm:px-6 py-3 flex-shrink-0 shadow-soft-xs">
        <div className="flex items-center justify-between gap-3 max-w-3xl mx-auto">
          <div className="flex items-center gap-3 min-w-0">
            <span className="text-2xl">{getCropIcon(prediction.crop)}</span>
            <div className="min-w-0">
              <p className="text-slate-900 dark:text-white text-sm font-black font-display truncate">
                {translatedCrop} • {translatedDisease}
              </p>
              <p className="text-slate-500 dark:text-slate-400 text-xs flex items-center gap-1 font-medium">
                <span>{t('chat_assistant')}</span>
                <span>{getDiseaseIcon(prediction.disease)}</span>
              </p>
            </div>
          </div>

          {confValue > 0 && (
            <div className="flex-shrink-0 bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 px-3 py-1 rounded-full text-emerald-700 dark:text-emerald-300 text-xs font-bold shadow-soft-xs">
              {confValue.toFixed(1)}%
            </div>
          )}
        </div>
      </div>

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto px-4 py-6 scrollbar-thin">
        <div className="max-w-3xl mx-auto space-y-4">

          {/* Suggestion chips */}
          {messages.length === 1 && (
            <div className="animate-fade-in-up">
              <p className="text-xs text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider mb-3 text-center">
                {t('chat_suggested_title')}
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                {chips.map(q => (
                  <button
                    key={q}
                    type="button"
                    onClick={() => handleSuggestion(q)}
                    disabled={isLoading}
                    className="text-left p-3.5 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md border border-slate-200/80 dark:border-slate-800 rounded-2xl text-xs font-semibold text-slate-700 dark:text-slate-300 hover:border-emerald-500 hover:bg-emerald-50/50 dark:hover:bg-emerald-950/30 transition-all disabled:opacity-50 shadow-soft-xs active:scale-98"
                  >
                    <span className="mr-1.5">💬</span>{q}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Messages */}
          {messages.map((msg, i) => {
            const isUser = msg.role === 'user';
            return (
              <div key={i} className={`flex ${isUser ? 'justify-end' : 'justify-start'} animate-slide-in-up`}>
                {!isUser && (
                  <div className="w-8 h-8 flex-shrink-0 rounded-2xl bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center mr-2.5 mt-0.5 shadow-glow-green text-white">
                    <Sparkles size={14} />
                  </div>
                )}
                <div
                  className={`
                    max-w-[85%] rounded-3xl p-4 shadow-soft-sm
                    ${isUser
                      ? 'bg-gradient-to-r from-emerald-600 to-green-600 text-white rounded-br-md shadow-glow-green'
                      : 'bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-slate-800 dark:text-slate-200 rounded-bl-md'
                    }
                  `}
                >
                  {isUser ? (
                    <p className="text-xs sm:text-sm text-white leading-relaxed font-medium">{msg.content}</p>
                  ) : (
                    <div className="text-slate-800 dark:text-slate-200 space-y-1.5 font-medium">
                      {renderContent(msg.content)}
                    </div>
                  )}
                  <p className={`text-[10px] mt-2 font-bold ${isUser ? 'text-white/70' : 'text-slate-400 dark:text-slate-500'}`}>
                    {new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </p>
                </div>
              </div>
            );
          })}

          {/* Typing indicator */}
          {isLoading && (
            <div className="flex justify-start animate-fade-in">
              <div className="w-8 h-8 flex-shrink-0 rounded-2xl bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center mr-2.5 shadow-glow-green text-white">
                <Sparkles size={14} />
              </div>
              <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-3xl rounded-bl-md p-4 shadow-soft-sm">
                <div className="flex gap-1.5 items-center">
                  {[0, 150, 300].map(delay => (
                    <div
                      key={delay}
                      className="w-2 h-2 bg-emerald-500 rounded-full animate-bounce"
                      style={{ animationDelay: `${delay}ms` }}
                    />
                  ))}
                  <span className="text-xs text-slate-400 dark:text-slate-500 ml-2 font-semibold">{t('chat_thinking')}</span>
                </div>
              </div>
            </div>
          )}

          <div ref={bottomRef} />
        </div>
      </div>

      {/* Input Form */}
      <div className="flex-shrink-0 max-w-3xl w-full mx-auto p-4">
        <form
          onSubmit={handleSubmit}
          className="border border-slate-200/90 dark:border-slate-800 bg-white/95 dark:bg-slate-900/95 backdrop-blur-xl p-2.5 rounded-3xl shadow-soft-xl flex gap-2"
        >
          <input
            ref={inputRef}
            type="text"
            value={text}
            onChange={e => setText(e.target.value)}
            placeholder={isLoading ? t('chat_thinking') : t('chat_ask_placeholder')}
            disabled={isLoading}
            className="flex-1 px-4 py-2.5 bg-transparent text-slate-800 dark:text-white placeholder-slate-400 dark:placeholder-slate-500 text-xs sm:text-sm focus:outline-none disabled:opacity-50"
          />
          <button
            type="submit"
            disabled={isLoading || !text.trim()}
            className="min-w-[44px] min-h-[44px] px-4 bg-gradient-to-r from-emerald-600 to-green-600 hover:from-emerald-500 hover:to-green-500 disabled:opacity-50 text-white rounded-2xl font-bold text-xs sm:text-sm transition-all shadow-glow-green active:scale-95 flex items-center justify-center gap-1.5"
          >
            <Send size={15} />
            <span className="hidden sm:inline">{t('chat_send')}</span>
          </button>
        </form>
      </div>
    </div>
  );
}

