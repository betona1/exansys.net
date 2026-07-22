import SnakeLogo from "./SnakeLogo";
import { COMPANY } from "../data/site";

export default function Footer() {
  return (
    <footer className="border-t border-white/10 bg-ink pb-11 pt-9 text-[13.5px] leading-relaxed text-white/55">
      <div className="mx-auto flex max-w-6xl flex-wrap justify-between gap-5 px-6">
        <div>
          <div className="mb-2">
            <SnakeLogo size={26} className="[&_span]:!text-white" />
          </div>
          <span className="block">
            {COMPANY.nameEn} ({COMPANY.nameKo})
          </span>
          <span className="block">
            대표: {COMPANY.ceo} · 사업자등록번호 {COMPANY.bizNo}
          </span>
          <span className="block">{COMPANY.addressEn}</span>
        </div>
        <div className="space-y-1">
          <a className="block text-white/75 hover:text-white" href="/#apps">앱</a>
          <a className="block text-white/75 hover:text-white" href="/#about">소개</a>
          <a className="block text-white/75 hover:text-white" href="/vibequest/reports">VibeQuest 문제 신고</a>
          <a className="block text-white/75 hover:text-white" href={`mailto:${COMPANY.email}`}>
            {COMPANY.email}
          </a>
          <span className="block pt-2">© 2026 EXANSYS Co., Ltd. All rights reserved.</span>
        </div>
      </div>
    </footer>
  );
}
