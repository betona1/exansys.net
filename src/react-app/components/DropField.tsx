// 파일을 넣는 입력칸 — 드래그앤드롭 · 클릭 선택 · 붙여넣기(Ctrl+V) 세 가지를 모두 받는다.
//
// 올린 파일은 R2 로 업로드하고 돌려받은 URL 을 값으로 넣는다. 주소를 직접 붙여넣어도
// 되도록 텍스트 입력은 그대로 남겨 둔다(외부 이미지호스트를 쓰는 경우).
import { useCallback, useRef, useState } from "react";
import { api } from "../lib/api";

type Props = {
  label: string;
  value: string;
  onChange: (url: string) => void;
  /** input accept 속성 */
  accept: string;
  placeholder?: string;
  hint?: string;
  /** 미리보기 종류 */
  preview?: "image" | "video";
};

const ERROR_TEXT: Record<string, string> = {
  unsupported_type: "지원하지 않는 형식입니다 (jpg·png·webp·gif·mp4·webm)",
  too_large: "파일이 너무 큽니다 (이미지 8MB · 영상 60MB)",
  empty_file: "빈 파일입니다",
  forbidden: "업로드 권한이 없습니다",
  unauthorized: "로그인이 필요합니다",
};

export default function DropField({
  label,
  value,
  onChange,
  accept,
  placeholder,
  hint,
  preview,
}: Props) {
  const [over, setOver] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);

  const upload = useCallback(
    async (file: File) => {
      setBusy(true);
      setError("");
      const res = await api<{ url: string }>("/api/admin/gallery-asset", {
        method: "POST",
        headers: { "Content-Type": file.type },
        body: file,
      });
      setBusy(false);
      if (res.ok) onChange(res.data.url);
      else setError(ERROR_TEXT[res.error] ?? `업로드 실패 (${res.error})`);
    },
    [onChange],
  );

  const takeFiles = useCallback(
    (files: FileList | null) => {
      const f = files?.[0];
      if (f) void upload(f);
    },
    [upload],
  );

  /** 붙여넣기 — 클립보드에 이미지가 있으면 업로드, 텍스트면 주소로 취급 */
  const onPaste = useCallback(
    (e: React.ClipboardEvent) => {
      const file = [...e.clipboardData.files][0];
      if (file) {
        e.preventDefault();
        void upload(file);
        return;
      }
      const text = e.clipboardData.getData("text").trim();
      if (/^https?:\/\//i.test(text)) {
        e.preventDefault();
        onChange(text);
      }
    },
    [upload, onChange],
  );

  return (
    <div>
      <label className="mb-1.5 block text-xs font-semibold text-muted">{label}</label>

      <div
        onDragOver={(e) => {
          e.preventDefault();
          setOver(true);
        }}
        onDragLeave={() => setOver(false)}
        onDrop={(e) => {
          e.preventDefault();
          setOver(false);
          takeFiles(e.dataTransfer.files);
        }}
        onPaste={onPaste}
        onClick={() => fileRef.current?.click()}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") fileRef.current?.click();
        }}
        role="button"
        tabIndex={0}
        className={`cursor-pointer rounded-xl border-2 border-dashed px-4 py-5 text-center text-sm transition ${
          over ? "border-green bg-green/10" : "border-line bg-paper hover:border-ink"
        }`}
      >
        {busy ? (
          <span className="inline-flex items-center gap-2 text-muted">
            <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-muted/40 border-t-muted" />
            올리는 중…
          </span>
        ) : (
          <>
            <p className="font-medium">파일을 여기에 끌어다 놓으세요</p>
            <p className="mt-1 text-xs text-muted">
              클릭해서 선택하거나, 이 칸을 누른 뒤 <b>Ctrl+V</b> 로 붙여넣어도 됩니다
            </p>
          </>
        )}
        <input
          ref={fileRef}
          type="file"
          accept={accept}
          className="hidden"
          onChange={(e) => takeFiles(e.target.files)}
        />
      </div>

      {/* 주소를 직접 넣는 경우 (외부 이미지호스트) */}
      <input
        className="mt-2 w-full rounded-xl border border-line bg-card px-4 py-2.5 text-sm outline-none focus:border-ink"
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
      />

      {hint && <p className="mt-1 text-xs text-muted">{hint}</p>}
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}

      {value && preview === "image" && (
        <img
          src={value}
          alt=""
          className="mt-2 aspect-video w-full rounded-xl border border-line object-cover"
        />
      )}
      {value && preview === "video" && !/youtube|youtu\.be/i.test(value) && (
        <video
          src={value}
          controls
          preload="metadata"
          className="mt-2 aspect-video w-full rounded-xl border border-line bg-black"
        />
      )}
    </div>
  );
}
