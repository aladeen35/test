import { useEffect, useState } from 'react';

const COLORS = ['#FFC928', '#4FB3E8', '#F26B5E', '#2FBF9B', '#7C5CBF', '#1E63C8'];

interface Piece {
  id: number;
  left: number;
  delay: number;
  duration: number;
  color: string;
}

export function Confetti({ count = 60 }: { count?: number }) {
  const [pieces, setPieces] = useState<Piece[]>([]);

  useEffect(() => {
    setPieces(Array.from({ length: count }, (_, i) => ({
      id: i,
      left: Math.random() * 100,
      delay: Math.random() * 0.8,
      duration: 2.2 + Math.random() * 1.8,
      color: COLORS[i % COLORS.length],
    })));
    const t = setTimeout(() => setPieces([]), 5000);
    return () => clearTimeout(t);
  }, [count]);

  return (
    <div aria-hidden="true">
      {pieces.map((p) => (
        <span
          key={p.id}
          className="confetti-piece"
          style={{
            left: `${p.left}%`,
            background: p.color,
            animationDelay: `${p.delay}s`,
            animationDuration: `${p.duration}s`,
          }}
        />
      ))}
    </div>
  );
}
