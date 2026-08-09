/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Palette derived from the "أنا مِنو" logo: deep blue frame,
        // sunny yellow accents, sky blue field, warm coral for alerts.
        navy: {
          DEFAULT: '#173B6C',
          dark: '#0F2A4F',
          deep: '#0A1F3D',
        },
        royal: {
          DEFAULT: '#1E63C8',
          light: '#3B82E0',
        },
        sky: {
          DEFAULT: '#4FB3E8',
          light: '#A8DCF7',
          pale: '#EAF6FE',
        },
        sun: {
          DEFAULT: '#FFC928',
          deep: '#F5A800',
          pale: '#FFF3CC',
        },
        coral: {
          DEFAULT: '#F26B5E',
          deep: '#D94F42',
        },
        grape: {
          DEFAULT: '#7C5CBF',
        },
        mint: {
          DEFAULT: '#2FBF9B',
        },
      },
      fontFamily: {
        cairo: ['Cairo', 'Tahoma', 'Arial', 'sans-serif'],
      },
      borderRadius: {
        blob: '2rem',
      },
      boxShadow: {
        card: '0 4px 0 0 rgba(15, 42, 79, 0.18)',
        'card-lg': '0 6px 0 0 rgba(15, 42, 79, 0.22)',
        pop: '0 8px 24px -6px rgba(15, 42, 79, 0.35)',
      },
      keyframes: {
        floaty: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        wiggle: {
          '0%, 100%': { transform: 'rotate(-3deg)' },
          '50%': { transform: 'rotate(3deg)' },
        },
        'pop-in': {
          '0%': { transform: 'scale(0.85)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        'slide-up': {
          '0%': { transform: 'translateY(24px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        shake: {
          '0%, 100%': { transform: 'translateX(0)' },
          '20%': { transform: 'translateX(-6px)' },
          '40%': { transform: 'translateX(6px)' },
          '60%': { transform: 'translateX(-4px)' },
          '80%': { transform: 'translateX(4px)' },
        },
        pulse_soft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.6' },
        },
      },
      animation: {
        floaty: 'floaty 3.5s ease-in-out infinite',
        wiggle: 'wiggle 2.5s ease-in-out infinite',
        'pop-in': 'pop-in 0.25s ease-out both',
        'slide-up': 'slide-up 0.3s ease-out both',
        shake: 'shake 0.45s ease-in-out',
        'pulse-soft': 'pulse_soft 1.6s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
