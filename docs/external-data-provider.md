# 外部データ取得候補メモ

## 目的

このメモは、外部API連携に進む前に、無料API前提の候補比較、Provider責務、APIキー管理、キャッシュ、エラー表示方針を整理するためのものです。

現時点では、実際のネットワーク通信、APIキー保存、認証、バックグラウンド更新、リアルタイム取得は実装しません。外部APIレスポンス相当のデータを `StockSnapshot` に変換する境界だけを先に固め、`AlertRuleEvaluator` が外部API形式に依存しない状態を維持します。

## 初期方針

- まずは無料APIで開始する。
- 有料API契約、有料API前提の設計、課金前提の機能分岐は現時点では行わない。
- 日本株、日経225、東証銘柄コードとの相性を重視する。
- 第一候補は J-Quants とする。ただし、採用確定前に無料プラン、利用規約、再配布制約、レート制限、取得可能期間を公式情報で再確認する。
- Alpha Vantage と Finnhub は代替候補として残すが、日本株コード体系、無料枠、取得できる指標、商用利用条件を確認してから採用判断する。

## 共通方針

- 外部APIのレスポンスは、画面や `AlertRuleEvaluator` に直接渡さない。
- API固有レスポンスは DTO に変換し、さらに `StockSnapshot` に変換してから条件評価に使う。
- `AlertRuleEvaluator` は `AlertRule` と `StockSnapshot` だけを入力にする。
- currentPrice、PER、PBR、出来高はいずれも欠損する可能性があるため Optional として扱う。
- すべての指標値が欠損している外部データは、有効な `StockSnapshot` として扱わない。
- 条件一致は、ユーザー設定条件と評価用データが一致した事実であり、売買推奨ではない。

## 共通DTO

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

## 候補API比較

外部APIのプラン、制限、商用利用条件は変更される可能性があります。実装直前に必ず公式サイトと利用規約を再確認します。

| 候補 | 初期判断 | 日本株・東証コードとの相性 | 無料枠 | APIキー / 認証 | currentPrice相当 | PER / PBR | 出来高 | 更新頻度・遅延 | レート制限・取得可能期間 | 注意点 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| J-Quants API | 第一候補 | 日本株向けで、東証銘柄コードとの相性が最も良い想定 | あり。無料プランの詳細は導入直前に公式確認 | 必要。認証方式とトークン更新方式を確認する | daily quotes の終値・四本値を currentPrice 相当として扱える可能性が高い | statements や財務データから取得または算出できる可能性がある。無料枠での取得範囲は要確認 | daily quotes に含まれる可能性が高い | 無料プランでは直近データの遅延がある可能性がある | プラン別のAPIコール数、取得可能期間、対象エンドポイントを要確認 | 利用規約、再配布制約、アプリ内表示可否を必ず確認する |
| Alpha Vantage | 代替候補 | グローバル株式向け。日本株コード体系との対応は要確認 | Free API key がある | 必要 | Daily / Quote 系で価格を取得できる可能性がある | Company Overview やFundamental系で取得できる可能性がある | Daily / Quote 系で取得できる可能性がある | 無料/有料でデータ鮮度や取得範囲が異なる可能性がある | 無料キーでは一部機能や取得量に制限あり。公式のPremium表記を確認する | 東証コード指定方法、日本株カバレッジ、商用利用条件がリスク |
| Finnhub | 代替候補 | グローバル株式向け。日本株カバレッジは要確認 | Free plan がある | 必要 | Quote系で取得できる可能性がある | Fundamentals系で取得できる可能性がある | Candles / Quote系で取得できる可能性がある | プランにより異なる | Free planのレート制限と対象データを要確認 | 日本株コード体系、無料枠の対象、商用利用条件がリスク |

参考公式URL:

- J-Quants: `https://jpx-jquants.com/en`
- J-Quants API Docs: `https://jpx.gitbook.io/j-quants-en/`
- Alpha Vantage: `https://www.alphavantage.co/documentation/`
- Finnhub: `https://finnhub.io/docs/api`

## 無料APIで取得する対象

初期の外部API連携では、以下を優先します。

- currentPrice: 日足の終値または最新取得可能な価格を使う。無料APIでリアルタイム性は求めない。
- volume: 日足の出来高を使う。
- PER: APIで直接取得できない場合は、必要な財務データと株価から算出できるか確認する。
- PBR: APIで直接取得できない場合は、必要な財務データと株価から算出できるか確認する。

無料APIでは難しい可能性がある対象:

- リアルタイム株価
- 直近当日データ
- 高頻度更新
- PER / PBR の即時取得
- 任意銘柄すべての安定取得
- 長期間の過去データ一括取得

## 有料APIの検討条件

有料APIは、以下のいずれかが明確になった場合だけ後続で検討します。

- 無料APIのレート制限でユーザー確認用途にも足りない
- PER / PBR / 出来高 / 株価の取得範囲が不足する
- データの遅延が大きく、ユーザー確認用途でも不便
- 日経225以外の任意銘柄対応に限界がある
- 利用規約上、アプリでの利用に制約が大きい
- 無料APIの安定性や提供継続性に不安がある

このStepでは、有料API契約、有料API前提の実装、プレミアム機能前提の分岐は行いません。

## Provider責務

外部データ取得まわりの責務は以下のように分けます。

| 型 | 責務 |
| --- | --- |
| `ExternalStockSnapshotResponse` | 外部データをアプリ内共通形式で受けるDTO |
| `ExternalStockDataProviding` | 外部由来データProviderのプロトコル |
| `StubExternalStockDataProvider` | 疑似レスポンスを返すテスト・開発用Provider |
| `ExternalApiStockDataProvider` | 将来の実通信Clientを使ってSnapshotを返すProvider。現時点ではClientの結果を処理するだけ |
| `ExternalStockDataClient` | 将来のURLSession通信を担う予定のプロトコル |
| `JQuantsStockDataClient` | J-Quants用Clientの設計スタブ。実通信はまだしない |
| `JQuantsStockDataMapper` | J-Quantsレスポンス相当のDTOを `ExternalStockSnapshotResponse` へ変換するMapper |

通常起動時の構成:

1. `ManualInputStockDataProvider`
2. `MockStockDataProvider`

開発・テスト用の3段階構成:

1. `ManualInputStockDataProvider`
2. `StubExternalStockDataProvider`
3. `MockStockDataProvider`

将来、無料API連携を有効にした場合の構成:

1. `ManualInputStockDataProvider`
2. `ExternalApiStockDataProvider`
3. `MockStockDataProvider`

通常起動時には、空の外部API Provider を挟みません。APIキー未設定や通信未実装の状態で余計な失敗状態を作らないためです。

## APIキー管理方針

- APIキーをソースコードに直書きしない。
- APIキーや秘密情報を GitHub に push しない。
- 初期実装では、ローカル設定ファイル、環境変数、Xcode Scheme 環境変数を候補にする。
- 将来的には Keychain 保存も検討する。
- ユーザー配布アプリにする場合、APIキーをアプリに埋め込むのか、バックエンド経由にするのかを別途設計する。
- APIキー未設定時は、外部APIを使わず手入力値または固定モック値で評価できるようにする。

## エラーとUI表示方針

外部API連携時の失敗は、DataProvider層で扱います。

| ケース | DataProvider / Clientでの扱い | UI表示方針 |
| --- | --- | --- |
| APIキー未設定 | `apiKeyNotConfigured` | 「外部データを取得できませんでした」など中立的に表示。手入力値または固定モック値へフォールバック可能 |
| 無料枠のレート制限 | `rateLimited` | 「無料APIの制限により、取得頻度を抑えています」 |
| 通信失敗 | `fetchFailed` | 「外部データを取得できませんでした」 |
| 銘柄コード未対応 | `nil` または `fetchFailed` | 「この銘柄の外部データは未取得です」 |
| 一部指標欠損 | DTO内の該当指標を nil | 「一部の指標が未取得です」「この指標は評価できません」 |
| 全指標欠損 | `missingRequiredValues` | 有効な `StockSnapshot` を作らずフォールバック |
| データ遅延 | `sourceName` または将来のステータスで表現 | 「取得可能な最新データを表示しています」 |
| キャッシュのみ利用中 | 将来の cacheStatus で表現 | 「前回取得値を表示しています」 |

UI文言は、条件一致の事実や取得状態を示すだけにします。売買判断を促す表現は使いません。

## キャッシュ方針

無料APIはレート制限がある可能性が高いため、外部API実通信時にはキャッシュを前提にします。

キャッシュ対象:

- currentPrice
- PER
- PBR
- volume
- capturedAt
- sourceName
- 将来の cacheStatus

キャッシュ保存先候補:

- SwiftData: アプリ再起動後も保持したい場合
- メモリ: 同一起動中の重複取得抑制
- ファイル: APIレスポンスの検証や簡易キャッシュ。ただし構造化しづらいため優先度は低い

初期方針:

- currentPrice / volume は同一銘柄で短時間の再取得を避ける。
- PER / PBR は更新頻度が低い可能性が高いため、株価より長めのキャッシュを検討する。
- レート制限時は、前回取得済みのキャッシュがあればそれを使う。
- ユーザーには必要に応じて「前回取得値」であることを表示する。
- 条件一致履歴には、`sourceName` にキャッシュ由来であることを含めるか、将来 `cacheStatus` を追加して残す。

将来の追加候補:

- `StockSnapshotCacheStatus`
- `isCached`
- `cacheExpiresAt`
- `fetchedAt`

このStepでは、キャッシュのSwiftData保存実装は行いません。

## 後続で決めること

- J-Quantsを正式採用するか
- 無料プランの正確なAPIコール制限
- 無料プランの取得可能期間
- PER / PBR を直接取得するか算出するか
- APIキー保存方式
- URLSession通信とレスポンスパース
- キャッシュ有効期限
- 外部APIの利用規約に合わせた表示・再配布制約
