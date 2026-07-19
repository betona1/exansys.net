// TechDex 사운드 효과 — Web Audio API로 즉석 합성 (오디오 파일 없이).
// 브라우저 자동재생 정책상 첫 사용자 제스처(퀴즈 시작 클릭)에서 unlock() 호출 필요.
type AC = AudioContext;

let ac: AC | null = null;
let muted = typeof localStorage !== "undefined" && localStorage.getItem("techdex_mute") === "1";

export function isMuted() {
  return muted;
}
export function setMuted(m: boolean) {
  muted = m;
  try {
    localStorage.setItem("techdex_mute", m ? "1" : "0");
  } catch {
    /* ignore */
  }
}

function ctx(): AC | null {
  try {
    if (!ac) {
      const Ctor = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
      if (!Ctor) return null;
      ac = new Ctor();
    }
    if (ac.state === "suspended") void ac.resume();
    return ac;
  } catch {
    return null;
  }
}

/** 사용자 제스처에서 오디오 컨텍스트를 깨운다. */
export function unlockAudio() {
  ctx();
}

function beep(freq: number, start: number, dur: number, type: OscillatorType, peak: number) {
  const a = ctx();
  if (!a) return;
  const t0 = a.currentTime + start;
  const osc = a.createOscillator();
  const g = a.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, t0);
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(peak, t0 + 0.008);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  osc.connect(g).connect(a.destination);
  osc.start(t0);
  osc.stop(t0 + dur + 0.03);
}

// 정답: 밝은 두 음 상승 차임
export function sfxCorrect() {
  if (muted) return;
  beep(660, 0, 0.12, "sine", 0.22);
  beep(988, 0.09, 0.2, "sine", 0.22);
}

// 오답: 낮게 깔리는 벗 소리
export function sfxWrong() {
  if (muted) return;
  beep(207, 0, 0.22, "sawtooth", 0.16);
  beep(155, 0.09, 0.26, "sawtooth", 0.14);
}

// 째깍: 아주 짧은 클릭 (초침 소리)
export function sfxTick() {
  if (muted) return;
  beep(1500, 0, 0.018, "square", 0.05);
}

// 시간 임박 경고음(선택)
export function sfxUrgent() {
  if (muted) return;
  beep(880, 0, 0.05, "square", 0.09);
}
