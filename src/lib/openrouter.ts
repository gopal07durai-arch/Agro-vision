const GEMINI_API_KEY = (import.meta.env.VITE_GEMINI_API_KEY || "").trim();
const DEFAULT_MODEL = "gemini-2.0-flash";

export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content:
    | string
    | Array<{
        type: "text" | "image_url";
        text?: string;
        image_url?: { url: string };
      }>;
}

const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

function inferMimeType(dataUrl: string): string {
  if (dataUrl.startsWith("data:image/png")) return "image/png";
  if (dataUrl.startsWith("data:image/webp")) return "image/webp";
  if (dataUrl.startsWith("data:image/jpeg")) return "image/jpeg";
  return "image/jpeg";
}

function dataUrlToBase64(dataUrl: string): string {
  const match = dataUrl.match(/^data:.+;base64,(.+)$/);
  return match ? match[1] : "";
}

function buildGeminiContents(messages: ChatMessage[]) {
  const systemMessage = messages.find(message => message.role === "system");
  const contents = messages
    .filter(message => message.role !== "system")
    .map(message => {
      const role = message.role === "assistant" ? "model" : "user";

      if (typeof message.content === "string") {
        return {
          role,
          parts: [{ text: message.content }],
        };
      }

      const parts = message.content.map(part => {
        if (part.type === "text") {
          return { text: part.text || "" };
        }

        if (part.type === "image_url") {
          return {
            inlineData: {
              mimeType: inferMimeType(part.image_url?.url || ""),
              data: dataUrlToBase64(part.image_url?.url || ""),
            },
          };
        }

        return { text: "" };
      });

      return {
        role,
        parts,
      };
    });

  return {
    systemInstruction: systemMessage
      ? {
          parts: [{ text: typeof systemMessage.content === "string" ? systemMessage.content : "" }],
        }
      : undefined,
    contents,
  };
}

export async function callOpenRouter(
  messages: ChatMessage[],
  model: string = DEFAULT_MODEL,
  retryCount: number = 0
): Promise<string> {
  if (!GEMINI_API_KEY) {
    return "Google AI Studio API key is not configured. Please add VITE_GEMINI_API_KEY to the environment.";
  }

  try {
    const payload = buildGeminiContents(messages);
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-goog-api-key": GEMINI_API_KEY,
        },
        body: JSON.stringify({
          systemInstruction: payload.systemInstruction,
          contents: payload.contents,
          generationConfig: {
            temperature: 0.4,
            maxOutputTokens: 1200,
          },
        }),
      }
    );

    if (response.status === 429) {
      return "The AI service is currently busy or your Google AI Studio quota has been exhausted. Please wait a moment and try again, or use a different API key.";
    }

    if (!response.ok) {
      let errMessage = "AI server error. Please upload a clear crop image and try again.";
      let rawError: unknown;
      try {
        rawError = await response.json();
        errMessage = (rawError as any)?.error?.message || errMessage;
      } catch {
        // ignore JSON parse failures
      }

      console.error("Gemini API Error:", rawError || errMessage);

      if (response.status === 400 || response.status === 401 || response.status === 403) {
        return `Google AI Studio rejected the request: ${errMessage}. Please verify that your API key is valid and enabled for the Gemini API.`;
      }

      if (response.status >= 500) {
        return `The Gemini service is temporarily unavailable. Please try again in a moment. If the issue continues, verify your Google AI Studio API key and quota.`;
      }

      if (response.status === 404) {
        return `The selected Gemini model is not available for this key. Please verify the API key and try again.`;
      }

      return errMessage;
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part.text)
      .filter(Boolean)
      .join("\n") || "";

    return text || "No response from AI.";
  } catch (error) {
    console.error("Gemini call failed:", error);
    return "Network error. Please check your internet connection.";
  }
}

// ---------------- IMAGE ANALYSIS ----------------

export async function analyzeImageForCropDisease(
  _imageDataUrl: string,
  _conversationHistory: ChatMessage[] = [],
  _cropHint?: string
): Promise<string> {
  // Production prediction relies strictly on real ML inference pipeline (FastAPI /predict endpoint)
  // No hardcoded fallback crops or fake predictions.
  return "Please process your leaf image through the AgroVision AI prediction pipeline.";
}

// ---------------- TEXT CHAT ----------------

export async function getChatResponse(
  conversationHistory: ChatMessage[],
  systemContext: string
): Promise<string> {
  const messages: ChatMessage[] = [
    { role: "system", content: systemContext },
    ...conversationHistory,
  ];

  return await callOpenRouter(messages);
}
