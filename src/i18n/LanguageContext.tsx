import React, { createContext, useState, useEffect, useCallback } from 'react';
import type { LanguageCode, TranslationKey, TranslationDictionary } from './types';
import { en } from './translations/en';
import { ta } from './translations/ta';
import { hi } from './translations/hi';
import { te } from './translations/te';
import { ml } from './translations/ml';

const TRANSLATIONS: Record<LanguageCode, TranslationDictionary> = {
  en,
  ta,
  hi,
  te,
  ml,
};

const STORAGE_KEY = 'agrovision-language-v2';

export interface LanguageContextType {
  language: LanguageCode;
  setLanguage: (lang: LanguageCode) => void;
  t: (key: TranslationKey, params?: Record<string, string | number>) => string;
  translateCrop: (cropName: string) => string;
  translateDisease: (diseaseName: string) => string;
  translateSeverity: (severity: string) => string;
  languageName: string;
}

export const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<LanguageCode>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved && (saved === 'en' || saved === 'ta' || saved === 'hi' || saved === 'te' || saved === 'ml')) {
        return saved as LanguageCode;
      }
    } catch {
      /* ignore */
    }
    return 'en';
  });

  const setLanguage = useCallback((lang: LanguageCode) => {
    setLanguageState(lang);
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch {
      /* ignore */
    }
  }, []);

  // Primary dictionary with fallback to English
  const t = useCallback((key: TranslationKey, params?: Record<string, string | number>): string => {
    const currentDict = TRANSLATIONS[language] || TRANSLATIONS.en;
    let text = currentDict[key] || TRANSLATIONS.en[key] || String(key);

    if (params) {
      Object.entries(params).forEach(([pKey, val]) => {
        text = text.replace(new RegExp(`{\\s*${pKey}\\s*}`, 'g'), String(val));
      });
    }

    return text;
  }, [language]);

  // Translate crop names dynamically
  const translateCrop = useCallback((cropName: string): string => {
    if (!cropName) return '';
    // Normalize crop key e.g. "Tomato", "Paddy", "Paddy / Rice" -> "crop_Tomato"
    let cleanCrop = cropName.split('/')[0].trim();
    cleanCrop = cleanCrop.charAt(0).toUpperCase() + cleanCrop.slice(1);
    const key = `crop_${cleanCrop}` as TranslationKey;
    const currentDict = TRANSLATIONS[language] || TRANSLATIONS.en;
    return currentDict[key] || TRANSLATIONS.en[key] || cropName;
  }, [language]);

  // Translate disease names dynamically
  const translateDisease = useCallback((diseaseName: string): string => {
    if (!diseaseName) return '';
    const cleanDisease = diseaseName.replace(/[^a-zA-Z0-9]/g, '');
    const key = `disease_${cleanDisease}` as TranslationKey;
    const currentDict = TRANSLATIONS[language] || TRANSLATIONS.en;
    return currentDict[key] || TRANSLATIONS.en[key] || diseaseName;
  }, [language]);

  // Translate severity labels
  const translateSeverity = useCallback((severity: string): string => {
    const currentDict = TRANSLATIONS[language] || TRANSLATIONS.en;
    switch (severity?.toLowerCase()) {
      case 'high':   return currentDict.severity_high   || TRANSLATIONS.en.severity_high;
      case 'medium': return currentDict.severity_medium || TRANSLATIONS.en.severity_medium;
      case 'low':    return currentDict.severity_low    || TRANSLATIONS.en.severity_low;
      case 'none':
      case 'healthy':return currentDict.severity_none   || TRANSLATIONS.en.severity_none;
      default:       return severity || currentDict.severity_medium;
    }
  }, [language]);

  const languageNames: Record<LanguageCode, string> = {
    en: 'English',
    ta: 'Tamil',
    hi: 'Hindi',
    te: 'Telugu',
    ml: 'Malayalam',
  };

  return (
    <LanguageContext.Provider
      value={{
        language,
        setLanguage,
        t,
        translateCrop,
        translateDisease,
        translateSeverity,
        languageName: languageNames[language],
      }}
    >
      {children}
    </LanguageContext.Provider>
  );
};
