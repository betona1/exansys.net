import { useEffect, useRef, type ReactNode } from "react";

/** 스크롤 진입 시 페이드업. prefers-reduced-motion은 CSS에서 처리. */
export default function Reveal({
  children,
  className = "",
  as: Tag = "div",
}: {
  children: ReactNode;
  className?: string;
  as?: "div" | "section" | "li";
}) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add("visible");
            io.unobserve(e.target);
          }
        }
      },
      { threshold: 0.12 },
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    // @ts-expect-error ref 타입은 태그별로 다르지만 HTMLElement로 충분
    <Tag ref={ref} className={`reveal ${className}`}>
      {children}
    </Tag>
  );
}
