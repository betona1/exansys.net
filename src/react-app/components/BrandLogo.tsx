// EXANSYS 로고 — 브랜드 가이드에서 뽑은 로고를 통짜 이미지로 쓴다.
//
// 심볼·워드마크·슬로건을 따로 조립하지 않는다. 가이드에 확정된 한 덩어리 그대로여야
// 자간·비율이 흐트러지지 않는다.
//
// 다크/라이트 두 장을 모두 그려 놓고 CSS 로 전환한다. 자바스크립트로 테마를 읽으면
// 첫 렌더에 반대쪽이 잠깐 보인다. 라이트용은 워드마크만 잉크색으로 바꾼 판이라
// 흰 배경에서도 배경과 어울린다.

type Variant = "horiz" | "full";

/** 추출한 로고 원본 비율 */
const RATIO: Record<Variant, number> = {
  horiz: 480 / 62, // 심볼 | EXANSYS / THINK AT EXA SCALE.
  full: 407 / 256, // 심볼 위, 워드마크·슬로건 아래
};

type Props = {
  /** 가로형(헤더·푸터) 또는 세로형(히어로) */
  variant?: Variant;
  /** 로고 높이(px). 가로는 비율에 맞춰 자동 */
  size?: number;
  /** 등장 + 은은한 시안 글로우 (히어로용) */
  animated?: boolean;
  className?: string;
};

export default function BrandLogo({
  variant = "horiz",
  size = 30,
  animated = false,
  className = "",
}: Props) {
  const width = Math.round(size * RATIO[variant]);
  const base = variant === "horiz" ? "/brand/logo-horiz" : "/brand/logo-full";

  return (
    <span
      className={`relative inline-block shrink-0 ${animated ? "brand-mark-animated" : ""} ${className}`}
      style={{ width, height: size }}
    >
      <img
        src={`${base}.png`}
        alt=""
        aria-hidden="true"
        width={width}
        height={size}
        className="brand-mark-dark absolute inset-0 h-full w-full object-contain"
      />
      <img
        src={`${base}-light.png`}
        alt=""
        aria-hidden="true"
        width={width}
        height={size}
        className="brand-mark-light absolute inset-0 h-full w-full object-contain"
      />
      <span className="sr-only">EXANSYS — THINK AT EXA SCALE.</span>
    </span>
  );
}
