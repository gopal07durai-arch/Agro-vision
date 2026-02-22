const OPENROUTER_API_KEY = import.meta.env.VITE_OPENROUTER_API_KEY;
const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";

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

// Vision supported model
const DEFAULT_MODEL = "openai/gpt-4o-mini";

// Delay helper
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

export async function callOpenRouter(
  messages: ChatMessage[],
  model: string = DEFAULT_MODEL,
  retryCount: number = 3
): Promise<string> {
  try {
    const response = await fetch(OPENROUTER_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": window.location.origin,
        "X-Title": "Farmer AI Chatbot"
      },
      body: JSON.stringify({
        model,
        messages,
        temperature: 0.4,
        max_tokens: 1200
      })
    });

    // Handle rate limit
    if (response.status === 429) {
      if (retryCount > 0) {
        console.warn("Rate limit hit. Retrying in 5 seconds...");
        await delay(5000);
        return callOpenRouter(messages, model, retryCount - 1);
      }
      return "Server busy. Please wait 10 seconds and try again.";
    }

    if (!response.ok) {
      const err = await response.json();
      console.error("OpenRouter API Error:", err);
      return "AI server error. Please upload a clear crop image and try again.";
    }

    const data = await response.json();
    return data?.choices?.[0]?.message?.content || "No response from AI.";

  } catch (error) {
    console.error("OpenRouter call failed:", error);
    return "Network error. Please check your internet connection.";
  }
}

// ---------------- IMAGE ANALYSIS ----------------

export async function analyzeImageForCropDisease(
  imageDataUrl: string,
  conversationHistory: ChatMessage[] = []
): Promise<string> {

  const systemPrompt = `
You are an expert agricultural AI assistant.

SUPPORTED CROPS:
Sugarcane, Turmeric, Groundnut, Blackgram, Sunflower, Wheat, Paddy (Rice), Eggplant (Brinjal), Cotton, Tomato.

RULES:
1. Always analyze the uploaded crop image.
2. Identify crop and disease if visible.
3. If image unclear, ask once for a clear leaf image taken in daylight.
4. Never repeat same error message.
5. Use simple farmer-friendly English.

Response format:
- I detected [CROP] with [DISEASE].
- OR I detected healthy [CROP].
- OR Unsupported crop.
- OR Please upload a clear leaf image taken in daylight.
`;

  const messages: ChatMessage[] = [
    { role: "system", content: systemPrompt },
    ...conversationHistory,
    {
      role: "user",
      content: [
        { type: "text", text: "Analyze this crop image and identify the crop and disease." },
        { type: "image_url", image_url: { url: imageDataUrl } }
      ]
    }
  ];

  return await callOpenRouter(messages);
}

// ---------------- TEXT CHAT ----------------

export async function getChatResponse(
  conversationHistory: ChatMessage[],
  systemContext: string
): Promise<string> {

  const messages: ChatMessage[] = [
    { role: "system", content: systemContext },
    ...conversationHistory
  ];

  return await callOpenRouter(messages);
}
