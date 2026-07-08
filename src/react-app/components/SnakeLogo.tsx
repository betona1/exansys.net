// EXANSYS 로고 — "X" 글자를 뱀이 감아 도는 엠블럼.
// 비늘은 다이아몬드 <pattern>, 몸통은 딥그린→라임 그라디언트.
// animated일 때 몸통이 그려지는 draw 애니메이션 + 은은한 하이라이트 루프 (CSS 담당).

const SNAKE_PATH =
  "M 18 84 C 4 74 8 56 22 50 C 38 43 62 43 74 32 C 82 25 80 14 70 12";

type Props = {
  /** 엠블럼 한 변 픽셀 크기 */
  size?: number;
  /** draw 애니메이션 여부 (히어로만 true, 헤더는 정적) */
  animated?: boolean;
  /** 워드마크 텍스트 표시 여부 */
  wordmark?: boolean;
  className?: string;
};

export default function SnakeLogo({
  size = 40,
  animated = false,
  wordmark = true,
  className = "",
}: Props) {
  const uid = animated ? "a" : "s"; // SVG id 충돌 방지
  return (
    <span className={`inline-flex items-center gap-[0.35em] ${className}`}>
      <svg
        width={size}
        height={size}
        viewBox="0 0 96 96"
        fill="none"
        aria-hidden="true"
        className={animated ? "snake-animated" : undefined}
      >
        <defs>
          <linearGradient id={`snakeGrad-${uid}`} x1="10" y1="86" x2="82" y2="12" gradientUnits="userSpaceOnUse">
            <stop offset="0" stopColor="#0E5741" />
            <stop offset="1" stopColor="#9BE15D" />
          </linearGradient>
          <pattern
            id={`scales-${uid}`}
            width="7"
            height="7"
            patternUnits="userSpaceOnUse"
            patternTransform="rotate(45)"
          >
            <rect width="7" height="7" fill="transparent" />
            <rect width="5.4" height="5.4" x="0.8" y="0.8" rx="1.4" fill="rgba(255,255,255,0.22)" />
          </pattern>
        </defs>

        {/* 타일 배경 */}
        <rect x="2" y="2" width="92" height="92" rx="22" fill="#12141C" />

        {/* X 워터마크 (뱀이 감는 대상) */}
        <path
          d="M 32 30 L 64 66 M 64 30 L 32 66"
          stroke="rgba(255,255,255,0.28)"
          strokeWidth="11"
          strokeLinecap="round"
        />

        {/* 뱀 몸통: 그라디언트 + 비늘 패턴 오버레이 */}
        <path
          className="snake-body"
          d={SNAKE_PATH}
          pathLength={1}
          stroke={`url(#snakeGrad-${uid})`}
          strokeWidth="10"
          strokeLinecap="round"
        />
        <path
          className="snake-body"
          d={SNAKE_PATH}
          pathLength={1}
          stroke={`url(#scales-${uid})`}
          strokeWidth="10"
          strokeLinecap="round"
        />
        {/* 하이라이트 루프 (animated일 때만 CSS로 재생) */}
        {animated && (
          <path
            className="snake-shine"
            d={SNAKE_PATH}
            pathLength={1}
            stroke="rgba(255,255,255,0.9)"
            strokeWidth="4"
            strokeLinecap="round"
          />
        )}

        {/* 머리 + 눈 */}
        <g className="snake-head">
          <circle cx="70" cy="12" r="7.5" fill="#9BE15D" />
          <circle cx="72.5" cy="10" r="1.8" fill="#12141C" />
        </g>
      </svg>
      {wordmark && (
        <span
          className="font-display font-extrabold tracking-wide text-ink"
          style={{ fontSize: size * 0.52 }}
        >
          EXANSYS
        </span>
      )}
    </span>
  );
}
