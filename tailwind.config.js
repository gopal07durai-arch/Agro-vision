/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
        display: ['Inter', 'Outfit', 'system-ui', 'sans-serif'],
      },
      colors: {
        forest: {
          800: '#064e3b',
          900: '#022c22',
          950: '#011910',
        },
      },
      boxShadow: {
        'soft-xs': '0 1px 2px 0 rgba(0, 0, 0, 0.04)',
        'soft-sm': '0 2px 8px -2px rgba(15, 23, 42, 0.06), 0 1px 4px -1px rgba(15, 23, 42, 0.04)',
        'soft-md': '0 8px 24px -6px rgba(15, 23, 42, 0.08), 0 4px 8px -2px rgba(15, 23, 42, 0.04)',
        'soft-xl': '0 20px 40px -15px rgba(15, 23, 42, 0.12), 0 8px 16px -6px rgba(15, 23, 42, 0.06)',
        'glow-green': '0 0 24px -4px rgba(22, 163, 74, 0.35)',
      },
      animation: {
        'ping-slow': 'ping 3s cubic-bezier(0, 0, 0.2, 1) infinite',
        'fade-in-up': 'fadeInUp 0.4s cubic-bezier(0.16, 1, 0.3, 1) both',
        'fade-in': 'fadeIn 0.3s ease both',
        'float-leaf-slow': 'floatLeafSlow 12s ease-in-out infinite',
        'float-leaf-reverse': 'floatLeafReverse 14s ease-in-out infinite',
        'sunlight-pulse': 'sunlightPulse 8s ease-in-out infinite alternate',
        'sun-drift': 'sunDrift 16s ease-in-out infinite alternate',
        'bounce-in': 'bounceIn 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) both',
      },
      keyframes: {
        fadeInUp: {
          from: { opacity: '0', transform: 'translateY(14px)' },
          to: { opacity: '1', transform: 'translateY(0)' },
        },
        fadeIn: {
          from: { opacity: '0' },
          to: { opacity: '1' },
        },
        floatLeafSlow: {
          '0%, 100%': { transform: 'translate(0, 0) rotate(0deg)' },
          '50%': { transform: 'translate(18px, -24px) rotate(14deg)' },
        },
        floatLeafReverse: {
          '0%, 100%': { transform: 'translate(0, 0) rotate(0deg)' },
          '50%': { transform: 'translate(-16px, -20px) rotate(-12deg)' },
        },
        sunlightPulse: {
          '0%': { opacity: '0.4', transform: 'scale(1)' },
          '100%': { opacity: '0.75', transform: 'scale(1.1)' },
        },
        sunDrift: {
          '0%': { transform: 'translate(0, 0)' },
          '100%': { transform: 'translate(25px, -20px)' },
        },
        bounceIn: {
          '0%': { opacity: '0', transform: 'scale(0.75)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
      },
    },
  },
  plugins: [],
};

