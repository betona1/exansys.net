// 바브바브(VAVEVAVE) — EXANSYS 마스코트.
//
// 바이브코딩을 배우는 캐릭터로, AI 에이전트와 합쳐지며 5단계까지 진화한다.
// 지금 사이트에 쓰는 건 1단계 — 호기심 많고 질문을 던지는 탐구자다.
// 그래서 "질문", "아직 없음", "무엇을 만들까" 같은 자리에 세울 때 가장 잘 맞는다.
//
// 자산은 public/mascot/ 에 세 가지로 두었다.
//   full : 전신 (히어로·CTA)
//   bust : 상반신 (섹션 옆)
//   face : 얼굴 정사각 (뱃지·아바타·빈 상태)

type Variant = "full" | "bust" | "face";

/** 원본 비율 (가로/세로) */
const RATIO: Record<Variant, number> = {
  full: 787 / 1090,
  bust: 646 / 632,
  face: 1,
};

const SRC: Record<Variant, { src: string; srcSet?: string }> = {
  full: {
    src: "/mascot/vavevave-01.webp",
    srcSet: "/mascot/vavevave-01.webp 1x, /mascot/vavevave-01@2x.webp 2x",
  },
  bust: { src: "/mascot/vavevave-01-bust.webp" },
  face: { src: "/mascot/vavevave-01-face.webp" },
};

type Props = {
  variant?: Variant;
  /** 세로 크기(px). 가로는 비율에 맞춰 자동 */
  size?: number;
  /** 위아래로 천천히 떠다닌다 */
  float?: boolean;
  /** 좌우 반전 (반대편에 세울 때) */
  flip?: boolean;
  className?: string;
  /** 장식이 아니라 내용일 때만 대체 텍스트를 준다 */
  alt?: string;
};

export default function Mascot({
  variant = "full",
  size = 160,
  float = false,
  flip = false,
  className = "",
  alt,
}: Props) {
  const width = Math.round(size * RATIO[variant]);
  const { src, srcSet } = SRC[variant];

  return (
    <img
      src={src}
      srcSet={srcSet}
      width={width}
      height={size}
      alt={alt ?? ""}
      aria-hidden={alt ? undefined : "true"}
      loading="lazy"
      decoding="async"
      className={`select-none object-contain ${float ? "mascot-float" : ""} ${
        flip ? "-scale-x-100" : ""
      } ${className}`}
      style={{ width, height: size }}
    />
  );
}
