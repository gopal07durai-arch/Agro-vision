import { Message } from '../lib/supabase';

interface ChatMessageProps {
  message: Message;
  onDropdownSelect?: (value: string) => void;
}

export function ChatMessage({ message, onDropdownSelect }: ChatMessageProps) {
  const isUser = message.role === 'user';

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-4`}>
      <div
        className={`max-w-[80%] rounded-2xl px-4 py-3 ${
          isUser
            ? 'bg-green-600 text-white'
            : 'bg-white text-gray-800 shadow-md border border-gray-200'
        }`}
      >
        {message.imageUrl && (
          <div className="mb-2">
            <img
              src={message.imageUrl}
              alt="Uploaded crop"
              className="rounded-lg max-w-full h-auto max-h-64 object-contain"
            />
          </div>
        )}
        {message.content.includes('<') && message.content.includes('>') ? (
          <div 
            className="whitespace-pre-wrap break-words"
            dangerouslySetInnerHTML={{ __html: message.content }}
          />
        ) : (
          <div className="whitespace-pre-wrap break-words">{message.content}</div>
        )}
        
        {/* Dropdown section */}
        {message.dropdown && (
          <div className="mt-3">
            <select
              onChange={(e) => {
                if (e.target.value && onDropdownSelect) {
                  onDropdownSelect(e.target.value);
                  e.target.value = ''; // Reset dropdown
                }
              }}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg bg-white text-gray-800 cursor-pointer focus:outline-none focus:ring-2 focus:ring-green-500"
              defaultValue=""
            >
              <option value="" disabled>
                Select an option...
              </option>
              {message.dropdown.options.map((option) => (
                <option key={option} value={option}>
                  {option}
                </option>
              ))}
            </select>
          </div>
        )}
        
        <div
          className={`text-xs mt-1 ${
            isUser ? 'text-green-100' : 'text-gray-500'
          }`}
        >
          {new Date(message.timestamp).toLocaleTimeString()}
        </div>
      </div>
    </div>
  );
}
