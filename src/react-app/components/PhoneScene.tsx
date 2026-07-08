// 히어로 대형 폰 목업 + 떠다니는 기능 칩 (alar.my 히어로 참고)
const CHIPS = [
  { icon: "✅", cls: "left-[8%] top-[18%] bg-lime/30", delay: "0s" },
  { icon: "⏱️", cls: "left-[16%] top-[52%] bg-amber-200/70", delay: "1.2s" },
  { icon: "📝", cls: "left-[26%] top-[80%] bg-sky-200/70", delay: "2.4s" },
  { icon: "🔔", cls: "right-[8%] top-[22%] bg-rose-200/70", delay: "0.6s" },
  { icon: "📊", cls: "right-[17%] top-[55%] bg-violet-200/70", delay: "1.8s" },
  { icon: "☁️", cls: "right-[27%] top-[82%] bg-emerald-200/70", delay: "3s" },
];

export default function PhoneScene() {
  return (
    <div aria-hidden="true" className="relative mx-auto mt-14 max-w-3xl">
      {/* 떠다니는 칩 */}
      {CHIPS.map((c) => (
        <div
          key={c.icon}
          className={`chip-float absolute hidden h-16 w-16 place-items-center rounded-2xl text-3xl shadow-lg backdrop-blur sm:grid ${c.cls}`}
          style={{ animationDelay: c.delay }}
        >
          {c.icon}
        </div>
      ))}

      {/* 폰 프레임 (하단이 패널에 잘리는 구도) */}
      <div className="mx-auto w-[300px] rounded-t-[3rem] bg-ink p-3 pb-0 shadow-2xl shadow-ink/30 sm:w-[340px]">
        <div className="h-[420px] overflow-hidden rounded-t-[2.4rem] bg-gradient-to-b from-white to-paper sm:h-[470px]">
          <div className="flex items-center justify-between px-7 pb-4 pt-5 text-[11px] font-bold text-muted">
            <span>9:41</span>
            <span>●●●</span>
          </div>
          <div className="px-5 text-left">
            <p className="font-display px-2 text-lg font-extrabold">오늘</p>
            <p className="px-2 pb-4 text-xs text-muted">수요일 · 7월 8일</p>
            {[
              { icon: "✅", title: "아침 루틴", sub: "3개 중 2개 완료", on: true },
              { icon: "⏱️", title: "집중 세션", sub: "25분 · 시작 대기", on: false },
              { icon: "🔔", title: "주간 리포트", sub: "오후 6:00", on: true },
            ].map((row) => (
              <div
                key={row.title}
                className="mb-3 flex items-center gap-3.5 rounded-2xl bg-white p-4 shadow-sm ring-1 ring-line"
              >
                <span className="grid h-11 w-11 place-items-center rounded-xl bg-paper text-xl">
                  {row.icon}
                </span>
                <span className="flex-1">
                  <span className="block text-sm font-bold">{row.title}</span>
                  <span className="block text-xs text-muted">{row.sub}</span>
                </span>
                <span
                  className={`relative h-6 w-11 rounded-full transition ${row.on ? "bg-green" : "bg-line"}`}
                >
                  <span
                    className={`absolute top-0.5 h-5 w-5 rounded-full bg-white shadow ${row.on ? "right-0.5" : "left-0.5"}`}
                  />
                </span>
              </div>
            ))}
            <div className="mt-4 rounded-2xl bg-ink p-4 text-white">
              <p className="text-[11px] text-white/60">이번 주 달성률</p>
              <p className="font-display mt-0.5 text-2xl font-extrabold">72%</p>
              <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-white/15">
                <div className="h-full w-[72%] rounded-full bg-lime" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
