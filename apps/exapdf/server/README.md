# ExaPDF OCR 서버

스캔본 PDF 를 받아 **글자로 바꿔 돌려주는** Django 서버.

앱이 직접 Ollama 를 부르던 방식을 대신한다. 앱이 하던 방식은 책 한 권에
한두 시간이 걸리는데 그동안 앱을 켜 두어야 했다 — 폰을 주머니에 넣는 순간
멈춘다. 서버가 큐를 들면 걸어 놓고 나가면 된다.

## 무엇이 어디서 도는가

```
앱  ──PDF 업로드──▶  Django (이 서버)  ──그림──▶  Ollama 비전 모델
    ◀──진행률 조회──                   ◀──글자──
    ◀──글자 내려받기─
```

- **Django** 는 접수·큐·체크포인트·결과 보관만 한다
- **그림 만들기**(pypdfium2)와 **글자 읽기 요청**은 워커 프로세스가 한다
- **추론**은 Ollama 가 한다. 이 서버와 같은 기기일 필요는 없다

라이선스: Django(BSD-3) · pypdfium2(Apache-2.0 / PDFium BSD-3) · Pillow(MIT-CMU).
**PyMuPDF 계열은 AGPL 이라 쓰지 않는다** (앱 CLAUDE.md 절대 규칙 1).

## 왜 이 구조인가

`CLAUDE.md` §8 이 요구하는 **상태머신 + 체크포인트**를 그대로 따랐다.

```
QUEUED → RENDERING → OCR → DONE
                      └──→ FAILED
```

- 쪽 하나를 마칠 때마다 DB 에 적는다. 워커가 죽어도 남은 쪽부터 이어 돈다
- 죽은 워커가 잡고 있던 일감은 `lease_expires_at` 이 지나면 자동으로 풀린다.
  사람이 손대야 풀리는 잠금은 결국 아무도 안 푼다

## 처음 띄우기

```bash
cd apps/exapdf/server
python -m pip install -r requirements.txt
cp .env.example .env      # OCR_ENDPOINT 와 API_TOKEN 을 채운다
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

다른 창에서 워커를 띄운다. **둘 다 떠 있어야 일이 진행된다.**

```bash
python manage.py ocr_worker
```

## API

모든 요청에 `Authorization: Bearer <API_TOKEN>` 이 필요하다.

| 메서드 | 경로 | 하는 일 |
|---|---|---|
| `GET` | `/api/health` | 서버·Ollama 상태 (토큰 불필요) |
| `POST` | `/api/jobs` | PDF 를 올려 일감을 만든다 (multipart, `file`) |
| `GET` | `/api/jobs/{uuid}` | 진행률·상태 |
| `GET` | `/api/jobs/{uuid}/pages?since=N` | N 쪽 다음부터 읽은 글자 |
| `POST` | `/api/jobs/{uuid}/cancel` | 멈춤 (이미 읽은 쪽은 남는다) |

같은 PDF 를 다시 올리면 **새 일감을 만들지 않고** 이미 있는 것을 돌려준다
(SHA-256 기준). 앱을 지웠다 깔아도 두 시간을 다시 기다리지 않는다.

## 앱에서 쓰기

`app/.env.json` 에 서버 주소와 토큰을 넣는다.

```json
{
  "ocrServer": "http://192.168.219.88:8000",
  "ocrServerToken": "...",
  "ocrEndpoint": "http://192.168.219.88:11434",
  "ocrModel": "qwen2.5vl:7b"
}
```

`ocrServer` 가 있으면 서버에 맡기고, 없으면 앱이 직접 Ollama 를 부른다.
직접 부르는 길을 남겨 둔 이유는 서버 없이도 쓸 수 있어야 하기 때문이다.

## 운영

MySQL 로 바꾸려면 `.env` 의 `DATABASE_URL` 만 채우면 된다 (기본은 SQLite).
앱에는 **DB 접속정보를 절대 내려보내지 않는다** — 앱은 이 API 만 부른다
(CLAUDE.md §2 규칙 3).
