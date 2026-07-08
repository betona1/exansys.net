import { useState } from "react";
import Reveal from "./Reveal";

/** alar.my 스타일 아코디언 FAQ */
export default function Faq({ items }: { items: { q: string; a: string }[] }) {
  const [open, setOpen] = useState<number | null>(null);

  return (
    <div className="space-y-3.5">
      {items.map((item, i) => {
        const isOpen = open === i;
        return (
          <Reveal key={item.q}>
            <div className="rounded-2xl border border-line bg-card transition hover:border-ink/25">
              <button
                onClick={() => setOpen(isOpen ? null : i)}
                aria-expanded={isOpen}
                className="flex w-full items-center gap-4 px-6 py-5 text-left"
              >
                <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-lime/25 text-sm font-extrabold text-green-deep">
                  Q
                </span>
                <span className="flex-1 font-semibold">{item.q}</span>
                <span
                  className={`text-xl text-muted transition-transform ${isOpen ? "rotate-45" : ""}`}
                  aria-hidden="true"
                >
                  +
                </span>
              </button>
              {isOpen && (
                <div className="px-6 pb-6 pl-18 text-[15px] leading-relaxed text-muted">
                  {item.a}
                </div>
              )}
            </div>
          </Reveal>
        );
      })}
    </div>
  );
}
