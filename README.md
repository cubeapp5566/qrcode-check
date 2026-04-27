# QRCode Check — 固定資產 QR 盤點系統

以 QR Code 掃描為核心的固定資產盤點工具。上傳 CSV 清單、列印 QR 標籤、用手機掃碼完成盤點，並即時查看進度。

---

## 功能

- **建立盤點任務**：上傳 CSV 資產清單，自訂資產編號欄位與地點欄位對應
- **QR 標籤列印**：一鍵產生全部資產的 QR Code 並列印（僅顯示 QR 與財產編號）
- **手機掃碼盤點**：掃描 QR Code 後記錄盤點人姓名、員工編號、備註及拍照存證
- **盤點清單檢視**：關鍵字搜尋、依狀態篩選（全部／已盤點／待盤點）
- **即時進度統計**：首頁顯示各任務完成率
- **匯出報表**：下載含盤點結果的 CSV 檔案
- **任務刪除**：需輸入刪除密碼，防止誤刪

---

## 技術架構

| 層 | 技術 |
|----|------|
| 前端 | React 19 + TypeScript + Vite |
| 後端 | Node.js + Express |
| 資料儲存 | JSON 檔案（`data/store.json`） |
| 掃碼 | html5-qrcode |
| QR 產生 | qrcode.react |

---

## 開發環境

```bash
npm install
npm run dev
```

- 前端：`http://localhost:5173`
- API：`http://localhost:4173`

---

## 正式部署

```bash
npm run build
npm start
```

服務統一跑在 `http://localhost:4173`（或 `PORT` 環境變數指定的 port）。

---

## 資料儲存

所有資料存放於 `data/` 目錄：

```
data/
  store.json       # 任務與資產盤點紀錄
  scan-photos/     # 盤點照片
```

首次啟動時自動建立，備份時複製整個 `data/` 即可。

---

## API 端點

| 方法 | 路徑 | 說明 |
|------|------|------|
| GET | `/api/tasks` | 取得任務清單 |
| POST | `/api/tasks` | 建立新任務 |
| GET | `/api/tasks/:id` | 取得任務詳情 |
| DELETE | `/api/tasks/:id` | 刪除任務（需密碼） |
| POST | `/api/tasks/:id/scan` | 記錄掃描結果 |
| GET | `/api/tasks/:id/export` | 匯出 CSV |
