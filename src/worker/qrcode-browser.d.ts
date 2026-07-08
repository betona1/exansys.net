// qrcode 브라우저 빌드(fs/pngjs 미포함, Workers 호환)의 타입 선언
declare module "qrcode/lib/browser" {
  import type QRCode from "qrcode";
  const q: Pick<typeof QRCode, "create" | "toDataURL" | "toString">;
  export default q;
}
