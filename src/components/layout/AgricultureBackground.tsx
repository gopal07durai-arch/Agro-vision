import { memo } from 'react';

/**
 * AgricultureBackground.tsx
 * Subtle, high-performance agricultural atmosphere background:
 * - Soft sunlight canopy ambient glow
 * - Gentle floating botanical leaves
 * - Delicate crop terrace wave contours
 * - Non-intrusive, pointer-events-none, respects reduced motion
 */
export const AgricultureBackground = memo(function AgricultureBackground() {
  return (
    <div
      className="fixed inset-0 pointer-events-none overflow-hidden select-none z-0"
      aria-hidden="true"
    >
      {/* 1. Base Gradient Layer */}
      <div className="absolute inset-0 bg-gradient-to-b from-emerald-50/70 via-slate-50/90 to-green-50/60 dark:from-slate-950 dark:via-forest-950/60 dark:to-slate-950 transition-colors duration-500" />

      {/* 2. Soft Sunlight Canopy Glow (Top Right) */}
      <div className="absolute -top-32 -right-32 w-[550px] h-[550px] rounded-full bg-gradient-to-br from-amber-200/20 via-emerald-300/15 to-transparent dark:from-emerald-500/10 dark:via-green-600/5 dark:to-transparent blur-3xl animate-sunlight-pulse" />

      {/* 3. Deep Field Atmosphere Orb (Bottom Left) */}
      <div className="absolute -bottom-40 -left-40 w-[600px] h-[600px] rounded-full bg-gradient-to-tr from-emerald-400/15 via-teal-400/10 to-transparent dark:from-emerald-900/20 dark:via-forest-900/15 dark:to-transparent blur-3xl animate-sun-drift" />

      {/* 4. Center Sunlight Accent */}
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-gradient-to-r from-emerald-400/10 via-green-300/15 to-emerald-400/10 dark:from-emerald-500/5 dark:via-green-500/5 dark:to-emerald-500/5 blur-3xl rounded-full" />

      {/* 5. Subtle Agricultural Landscape Contours (SVG Terrace Curves) */}
      <svg
        className="absolute bottom-0 left-0 right-0 w-full h-48 sm:h-64 text-emerald-600/5 dark:text-emerald-400/[0.03] transition-colors duration-500"
        viewBox="0 0 1440 320"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        preserveAspectRatio="none"
      >
        <path
          d="M0,192L60,181.3C120,171,240,149,360,160C480,171,600,213,720,218.7C840,224,960,192,1080,165.3C1200,139,1320,117,1380,106.7L1440,96L1440,320L1380,320C1320,320,1200,320,1080,320C960,320,840,320,720,320C600,320,480,320,360,320C240,320,120,320,60,320L0,320Z"
          fill="currentColor"
        />
        <path
          d="M0,256L48,240C96,224,192,192,288,197.3C384,203,480,245,576,250.7C672,256,768,224,864,192C960,160,1056,128,1152,133.3C1248,139,1344,181,1392,202.7L1440,224L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"
          fill="currentColor"
          opacity="0.6"
        />
      </svg>

      {/* 6. Gentle Floating Leaf Particles */}
      <div className="absolute inset-0">
        {/* Leaf 1: Top Left */}
        <div className="absolute top-[12%] left-[8%] animate-float-leaf-slow opacity-25 dark:opacity-20">
          <svg className="w-8 h-8 text-emerald-600 dark:text-emerald-400" viewBox="0 0 24 24" fill="currentColor">
            <path d="M17,8C8,10 5.9,16.17 3.82,21.34L5.71,22L6.66,19.7C7.14,19.87 7.64,20 8,20C19,20 22,3 22,3C21,5 14,5.25 9,6.25C4,7.25 2,11.5 2,13.5C2,15.5 3.75,17.25 3.75,17.25C7,8 17,8 17,8Z" />
          </svg>
        </div>

        {/* Leaf 2: Top Right */}
        <div
          className="absolute top-[18%] right-[12%] animate-float-leaf-reverse opacity-20 dark:opacity-15"
          style={{ animationDelay: '2s' }}
        >
          <svg className="w-10 h-10 text-green-600 dark:text-green-400 transform rotate-45" viewBox="0 0 24 24" fill="currentColor">
            <path d="M17,8C8,10 5.9,16.17 3.82,21.34L5.71,22L6.66,19.7C7.14,19.87 7.64,20 8,20C19,20 22,3 22,3C21,5 14,5.25 9,6.25C4,7.25 2,11.5 2,13.5C2,15.5 3.75,17.25 3.75,17.25C7,8 17,8 17,8Z" />
          </svg>
        </div>

        {/* Leaf 3: Mid-Left */}
        <div
          className="absolute top-[48%] left-[5%] animate-float-leaf-reverse opacity-20 dark:opacity-15"
          style={{ animationDelay: '4s' }}
        >
          <svg className="w-7 h-7 text-emerald-500 dark:text-emerald-400 transform -rotate-12" viewBox="0 0 24 24" fill="currentColor">
            <path d="M17,8C8,10 5.9,16.17 3.82,21.34L5.71,22L6.66,19.7C7.14,19.87 7.64,20 8,20C19,20 22,3 22,3C21,5 14,5.25 9,6.25C4,7.25 2,11.5 2,13.5C2,15.5 3.75,17.25 3.75,17.25C7,8 17,8 17,8Z" />
          </svg>
        </div>

        {/* Leaf 4: Mid-Right */}
        <div
          className="absolute top-[55%] right-[7%] animate-float-leaf-slow opacity-25 dark:opacity-20"
          style={{ animationDelay: '1s' }}
        >
          <svg className="w-9 h-9 text-teal-600 dark:text-teal-400 transform rotate-12" viewBox="0 0 24 24" fill="currentColor">
            <path d="M17,8C8,10 5.9,16.17 3.82,21.34L5.71,22L6.66,19.7C7.14,19.87 7.64,20 8,20C19,20 22,3 22,3C21,5 14,5.25 9,6.25C4,7.25 2,11.5 2,13.5C2,15.5 3.75,17.25 3.75,17.25C7,8 17,8 17,8Z" />
          </svg>
        </div>

        {/* Leaf 5: Bottom Center-Right */}
        <div
          className="absolute bottom-[22%] right-[22%] animate-float-leaf-slow opacity-15 dark:opacity-10"
          style={{ animationDelay: '3s' }}
        >
          <svg className="w-6 h-6 text-green-500 dark:text-green-400 transform rotate-90" viewBox="0 0 24 24" fill="currentColor">
            <path d="M17,8C8,10 5.9,16.17 3.82,21.34L5.71,22L6.66,19.7C7.14,19.87 7.64,20 8,20C19,20 22,3 22,3C21,5 14,5.25 9,6.25C4,7.25 2,11.5 2,13.5C2,15.5 3.75,17.25 3.75,17.25C7,8 17,8 17,8Z" />
          </svg>
        </div>
      </div>
    </div>
  );
});
