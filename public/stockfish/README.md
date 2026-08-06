# Stockfish 18 (NNUE) for SuperChess web

Engine builds from [nmrugg/stockfish.js](https://github.com/nmrugg/stockfish.js) v18.0.0.

| File | Role |
|------|------|
| `stockfish-18-lite-single.js` + `.wasm` | **Primary** — Stockfish 18 NNUE lite (~7MB), fast load. |
| `stockfish-18-single.js` + `.wasm` | Fallback full NNUE (~108MB) if lite fails. |
| `stockfish-18-lite.js` + `.wasm` | Optional multi-thread lite (needs COOP/COEP). |

Dart loads workers via `lib/chess/stockfish_engine_web.dart` (full single → lite single).

## Re-download

```powershell
.\scripts\fetch_stockfish.ps1
```

`*.wasm` is Git LFS-tracked. After clone: `git lfs pull`.
