# 外部データ取得候補メモ

## 目的

このメモは、Step 12 で外部API連携へ進む前に、外部データ取得候補とアプリ内の受け口を整理するためのものです。

Step 12 では、実際のネットワーク通信、APIキー保存、認証、バックグラウンド更新、リアルタイム取得は実装しません。まず、外部APIレスポンス相当のデータを `StockSnapshot` に変換する層を作り、`AlertRuleEvaluator` が外部API形式に依存しない状態を維持します。

## 共通方針

- 外部APIのレスポンスは、画面や `AlertRuleEvaluator` に直接渡さない。
- API固有のレスポンスは DTO に変換し、さらに `StockSnapshot` に変換してから条件評価に使う。
- `AlertRuleEvaluator` は `AlertRule` と `StockSnapshot` だけを入力にする。
- currentPrice、PER、PBR、出来高はいずれも欠損する可能性があるため Optional として扱う。
- すべての指標値が欠損している外部データは、有効な `StockSnapshot` として扱わない。
- 条件一致は、ユーザー設定条件と評価用データが一致した事実であり、売買推奨ではない。

## Step 12 で扱う共通DTO

外部API候補を確定する前に、アプリ内では以下のような中間DTOを使います。

| 項目 | 内容 |
| --- | --- |
| stockCode | 銘柄コード。必須 |
| currentPrice | 現在値または終値相当。任意 |
| per | PER。任意 |
| pbr | PBR。任意 |
| volume | 出来高。任意 |
| capturedAt | 取得日時。任意。欠損時は変換時点の日時を使う |
| sourceName | 取得元名。任意。欠損時は「外部API疑似データ」を使う |

外部API固有のレスポンスを直接この形にできない場合は、API別のDTOを追加し、この共通DTOまたは `StockSnapshot` へ変換します。

## 候補API

外部APIのプラン、制限、商用利用条件は変更される可能性があります。実装直前に必ず公式サイトと利用規約を再確認します。

| 候補 | 日本株データとの相性 | 現在値・株価 | PER / PBR | 出来高 | APIキー | 無料枠・制限 | 注意点 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| J-Quants API | 日本株向け。東証銘柄コードとの相性が良い | 株価四本値を取得可能 | 財務情報から取得または算出できる可能性がある | 株価四本値データに含まれる | 必要 | Free plan があり、APIコール制限や取得可能期間がある | 無料プランでは直近データに遅延がある。取得データの再配布や第三者提供の制約を確認する |
| Alpha Vantage | グローバル株式向け。日本株コード体系との対応は要確認 | Quote / Daily 系で価格や出来高を取得できる可能性がある | Company Overview などのFundamental系で取得できる可能性がある | Quote / Time Series 系で取得できる可能性がある | 必要 | Free API key がある。無料/有料で利用できるエンドポイントや鮮度が異なる | 東証銘柄コードの指定方法、対象銘柄カバレッジ、商用利用条件を確認する |
| Finnhub | グローバル株式向け。日本株カバレッジは要確認 | Quote系で取得できる可能性がある | Fundamentals系で取得できる可能性がある | Quoteまたはローソク足系で取得できる可能性がある | 必要 | Free plan とレート制限があるため要確認 | 日本株の銘柄コード体系、利用条件、取得頻度、商用利用条件を確認する |

参考公式URL:

- J-Quants: `https://jpx-jquants.com/en`
- Alpha Vantage: `https://www.alphavantage.co/documentation/`
- Finnhub: `https://finnhub.io/docs/api`

## エラーと欠損値の扱い

外部API連携時の失敗は、DataProvider層で扱います。

| ケース | 扱う層 | UIでの扱い |
| --- | --- | --- |
| APIキー未設定 | ExternalApiStockDataProvider | データを取得できない状態として中立的に表示 |
| レート制限 | ExternalApiStockDataProvider | データを取得できない状態として中立的に表示 |
| 通信失敗 | 将来のAPI client / Provider | データを取得できない状態として中立的に表示 |
| 一部指標の欠損 | DTO / StockSnapshot | 欠損した指標だけ「評価できません」 |
| 全指標の欠損 | DTO変換 | `StockSnapshot` を作らない |
| 銘柄コード未対応 | Provider | `nil` を返し、次のProviderへフォールバック |

## データ取得優先順位

将来の実行時優先順位は以下です。

1. 有効なユーザー手入力評価データ
2. 外部API由来の `StockSnapshot`
3. 開発用固定モック値

全項目空欄の手入力評価データは、有効な手入力評価データなしとして扱います。

Step 12 時点では実ネットワーク通信を行わないため、外部API層は疑似レスポンスから `StockSnapshot` を返すスタブとして扱います。

## 後続で決めること

- 採用するAPIと利用プラン
- APIキー保存方式
- レート制限時の再試行と待機方針
- キャッシュ期間
- 欠損値が多い場合のUI表示
- バックグラウンド更新の要否
- 取得データの保存範囲
- 外部APIの利用規約に合わせた表示・再配布制約
