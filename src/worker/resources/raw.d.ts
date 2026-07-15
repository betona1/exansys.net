// Vite ?raw 임포트 — 파일 내용을 문자열로 번들에 포함 (worker tsconfig엔 vite/client가 없어 직접 선언)
declare module "*.html?raw" {
  const content: string;
  export default content;
}
