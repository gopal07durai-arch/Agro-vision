import { useState, useRef, FormEvent, ChangeEvent } from 'react';
import { Wheat, Image as ImageIcon, X } from 'lucide-react';

interface ChatInputProps {
  onSendMessage: (message: string) => void;
  onSendImage: (imageDataUrl: string) => Promise<void>; // ✅ must be Promise
  disabled?: boolean;
  placeholder?: string;
}

export function ChatInput({
  onSendMessage,
  onSendImage,
  disabled = false,
  placeholder = 'Type your message...',
}: ChatInputProps) {
  const [message, setMessage] = useState('');
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // ---------------- SEND ----------------
  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (disabled || isUploading) return;

    try {
      if (selectedImage) {
        setIsUploading(true);
        await onSendImage(selectedImage);
        clearImage();
      } else if (message.trim()) {
        onSendMessage(message.trim());
        setMessage('');
      }
    } catch (error) {
      console.error('Send failed:', error);
      alert('Failed to send. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  // ---------------- IMAGE SELECT ----------------
  const handleImageSelect = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      alert('Please upload only image files.');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      alert('Image size should be less than 5MB.');
      return;
    }

    const reader = new FileReader();
    reader.onloadend = () => {
      setSelectedImage(reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  // ---------------- CLEAR IMAGE ----------------
  const clearImage = () => {
    setSelectedImage(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <form onSubmit={handleSubmit} className="border-t border-gray-200 bg-white p-4">

      {selectedImage && (
        <div className="mb-3 relative inline-block">
          <img
            src={selectedImage}
            alt="Selected crop"
            className="h-24 w-24 object-cover rounded-lg border-2 border-green-500"
          />
          <button
            type="button"
            onClick={clearImage}
            className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1"
          >
            <X size={14} />
          </button>
        </div>
      )}

      <div className="flex gap-2">

        {/* Hidden file input */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          onChange={handleImageSelect}
          className="hidden"
          disabled={disabled || isUploading}
        />

        {/* Upload Button */}
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          disabled={disabled || isUploading || !!selectedImage}
          className="p-3 bg-gray-100 rounded-lg hover:bg-gray-200 disabled:opacity-50"
          title="Upload crop image"
        >
          <ImageIcon size={20} />
        </button>

        {/* Text Input */}
        <input
          type="text"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder={placeholder}
          disabled={disabled || isUploading || !!selectedImage}
          className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
        />

        {/* Send Button */}
        <button
          type="submit"
          disabled={disabled || isUploading || (!message.trim() && !selectedImage)}
          className="p-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
        >
          {isUploading ? (
            <div className="animate-spin h-5 w-5 border-b-2 border-white rounded-full" />
          ) : (
            <Wheat size={20} />
          )}
        </button>
      </div>
    </form>
  );
}
