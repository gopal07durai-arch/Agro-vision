/**
 * useGeminiChat.ts
 * Custom hook for disease-scoped follow-up chatbot with i18n support.
 */

import { useState, useCallback, useEffect } from 'react';
import { getChatResponse } from '../services/geminiService';
import type { ChatMessage } from '../types';

interface UseGeminiChatOptions {
  crop: string;
  disease: string;
  languageName: string;
  t: (key: any, params?: any) => string;
  translateCrop: (crop: string) => string;
  translateDisease: (disease: string) => string;
}

function buildWelcome(
  crop: string,
  disease: string,
  t: (key: any, params?: any) => string,
  translateCrop: (c: string) => string,
  translateDisease: (d: string) => string
): ChatMessage {
  const tCrop = translateCrop(crop);
  const tDisease = translateDisease(disease);

  return {
    role: 'assistant',
    content: `${t('chat_welcome_msg')} **${tCrop}** (${tDisease}).`,
    timestamp: Date.now(),
  };
}

export function useGeminiChat({
  crop,
  disease,
  languageName,
  t,
  translateCrop,
  translateDisease,
}: UseGeminiChatOptions) {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    setMessages((prev) => {
      if (prev.length <= 1) {
        return [buildWelcome(crop, disease, t, translateCrop, translateDisease)];
      }
      return prev;
    });
  }, [crop, disease, languageName, t, translateCrop, translateDisease]);

  const suggestedQuestions = [
    t('chat_q1'),
    t('chat_q2'),
    t('chat_q3'),
  ];

  const sendMessage = useCallback(async (text: string) => {
    if (!text.trim() || isLoading) return;

    const userMsg: ChatMessage = {
      role: 'user',
      content: text.trim(),
      timestamp: Date.now(),
    };

    setMessages(prev => [...prev, userMsg]);
    setIsLoading(true);

    try {
      const allMessages = [...messages, userMsg];
      const responseText = await getChatResponse(crop, disease, allMessages, languageName);
      const assistantMsg: ChatMessage = {
        role: 'assistant',
        content: responseText,
        timestamp: Date.now(),
      };
      setMessages(prev => [...prev, assistantMsg]);
    } catch {
      setMessages(prev => [
        ...prev,
        {
          role: 'assistant',
          content: t('err_unexpected'),
          timestamp: Date.now(),
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  }, [messages, crop, disease, languageName, isLoading, t]);

  const reset = useCallback(() => {
    setMessages([buildWelcome(crop, disease, t, translateCrop, translateDisease)]);
  }, [crop, disease, t, translateCrop, translateDisease]);

  return { messages, isLoading, sendMessage, reset, suggestedQuestions };
}
