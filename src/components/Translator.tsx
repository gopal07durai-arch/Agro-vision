import { useState } from 'react';
import { Globe } from 'lucide-react';

interface TranslatorProps {
  onLanguageChange?: (language: string) => void;
}

const LANGUAGES = [
  { code: 'en', name: 'English' },
  { code: 'es', name: 'Spanish' },
  { code: 'fr', name: 'French' },
  { code: 'de', name: 'German' },
  { code: 'hi', name: 'Hindi' },
  { code: 'ja', name: 'Japanese' },
  { code: 'zh', name: 'Chinese' },
  { code: 'pt', name: 'Portuguese' },
  { code: 'ar', name: 'Arabic' },
  { code: 'ru', name: 'Russian' },
  { code: 'ta', name: 'Tamil' },
];

export function Translator({ onLanguageChange }: TranslatorProps) {
  const [selectedLanguage, setSelectedLanguage] = useState(() => {
    // Try to get language from the googtrans cookie if it exists
    const match = document.cookie.match(/(?:^|;)\s*googtrans=([^;]*)/);
    if (match) {
      const parts = match[1].split('/');
      const lang = parts[parts.length - 1];
      if (lang) return lang;
    }
    return 'en';
  });
  const [isOpen, setIsOpen] = useState(false);

  const API_KEY = import.meta.env.VITE_GOOGLE_TRANSLATE_API_KEY || '';

  const handleLanguageSelect = async (targetLang: string) => {
    setSelectedLanguage(targetLang);
    setIsOpen(false);

    // Update the native Google Translate dropdown
    const selectElement = document.querySelector('.goog-te-combo') as HTMLSelectElement | null;
    if (selectElement) {
      if (selectElement.value !== targetLang) {
        selectElement.value = targetLang;
        selectElement.dispatchEvent(new Event('change', { bubbles: true }));
      }
    } else {
      console.warn('Google Translate combo box not found.');
      // Fallback: set cookie and optionally reload
      document.cookie = `googtrans=/en/${targetLang}; path=/;`;
      document.cookie = `googtrans=/en/${targetLang}; domain=${window.location.hostname}; path=/;`;
      window.location.reload();
    }

    if (onLanguageChange) {
      onLanguageChange(targetLang);
    }
  };

  const currentLanguageName =
    LANGUAGES.find((lang) => lang.code === selectedLanguage)?.name || 'English';

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 bg-white/20 hover:bg-white/30 text-white px-3 py-2 rounded-lg transition-colors"
        title="Change Language"
      >
        <Globe size={20} />
        <span className="text-sm font-medium">{currentLanguageName}</span>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-48 bg-white text-gray-800 rounded-lg shadow-lg z-50">
          <div className="p-3 border-b border-gray-200">
            <p className="text-sm font-semibold text-gray-600">Select Language</p>
          </div>
          <div className="max-h-64 overflow-y-auto">
            {LANGUAGES.map((language) => (
              <button
                key={language.code}
                onClick={() => handleLanguageSelect(language.code)}
                className={`w-full text-left px-4 py-2 hover:bg-green-50 transition-colors ${selectedLanguage === language.code
                  ? 'bg-green-100 text-green-700 font-semibold'
                  : 'text-gray-700'
                  }`}
              >
                {language.name}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// Export the translate function for use throughout the app
export async function translateText(
  text: string,
  sourceLang: string,
  targetLang: string,
  apiKey: string
): Promise<string> {
  try {
    if (!apiKey) {
      console.warn('Google Translate API key not configured');
      return text;
    }

    const url = `https://translation.googleapis.com/language/translate/v2?key=${apiKey}&source=${sourceLang}&target=${targetLang}&q=${encodeURIComponent(
      text
    )}`;

    const response = await fetch(url, {
      method: 'POST',
    });

    if (!response.ok) {
      throw new Error(`Translation API error: ${response.statusText}`);
    }

    const data = await response.json();
    return data.data.translations[0].translatedText;
  } catch (error) {
    console.error('Translation error:', error);
    return text;
  }
}
