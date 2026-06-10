# データモデル設計

## 基本方針

初期版では SwiftData によるローカル保存を想定します。将来バックエンド化しやすくするため、銘柄マスタ、ウォッチリスト、投資メモ、アラート条件、通知履歴を分離します。

中心モデルは以下です。

- StockMaster
- WatchlistItem
- InvestmentMemo
- AlertRule
- AlertMatchHistory
- StockSnapshot

## StockMaster

StockMaster は、銘柄の基本情報を保持するモデルです。日経225銘柄の標準候補と、ユーザーが追加した任意銘柄を同じモデルで扱います。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| code | 銘柄コード |
| name | 銘柄名 |
| market | 市場区分 |
| industry | 業種 |
| isNikkei225 | 日経225採用銘柄かどうか |
| isUserAdded | ユーザー追加銘柄かどうか |
| source | nikkei225Mock、userInput、externalMaster など |
| sourceUpdatedAt | マスタ情報の更新日時 |
| createdAt | 作成日時 |
| updatedAt | 更新日時 |

設計メモ:

- code は日本株の銘柄コードを想定する
- 初期版では重複登録を避けるため、code を主な識別キーとして扱う
- 将来、証券取引所や国を扱う場合に備えて market や country を追加できるようにする
- 日経225採用銘柄かどうかは、ウォッチリストではなくマスタ側に持つ
- 日経225ローカルJSONには、可能であれば `sourceName`、`asOfDate`、`stocks` のようなメタ情報を持たせる
- `asOfDate` により、この日経225銘柄一覧がいつ時点のものかを分かるようにする
- 将来、外部マスタやAPI取得に差し替える場合も、取り込み元と更新時点を明確にする

ローカルJSONの構造例:

```json
{
  "sourceName": "nikkei225Mock",
  "asOfDate": "2026-06-06",
  "stocks": []
}
```

## WatchlistItem

WatchlistItem は、ユーザーが監視対象として選んだ銘柄を表します。StockMaster とは分離し、ユーザー固有の状態を持ちます。

Step 9 時点では、Domainモデルの `WatchlistItem` は通常の Swift 構造体として維持し、SwiftData保存用には `WatchlistItemRecord` を別に定義します。アプリ本体では `SwiftDataWatchlistRepository` が `WatchlistItem` と `WatchlistItemRecord` を変換し、View は SwiftData の `ModelContext` を直接扱いません。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| code | 銘柄コード |
| name | 銘柄名 |
| market | 市場区分 |
| industry | 業種 |
| isNikkei225 | 日経225標準候補かどうか |
| createdAt | 作成日時 |

`WatchlistItemRecord` は Step 9 では以下を保持します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| code | 銘柄コード |
| name | 銘柄名 |
| market | 市場区分 |
| industry | 業種 |
| isNikkei225 | 日経225標準候補かどうか |
| createdAt | 作成日時 |

将来の拡張候補:

| 項目 | 内容 |
| --- | --- |
| stockMasterId | 対象銘柄マスタID |
| isMonitoring | 監視中フラグ |
| note | ウォッチリスト用の短いメモ |
| displayOrder | 表示順 |
| addedAt | 追加日時 |
| updatedAt | 更新日時 |
| deletedAt | 将来同期向けの削除状態 |

設計メモ:

- 同じ StockMaster を、ユーザーがウォッチリストに追加した状態として扱う
- Step 5 時点では `WatchlistViewModel` が `WatchlistRepository` を利用し、WatchlistView と AddStockView で同じウォッチリスト状態を共有する
- Step 9 ではアプリ本体のウォッチリストを `SwiftDataWatchlistRepository` に差し替え、再起動後も保存されるようにする
- `InMemoryWatchlistRepository` はPreviewとテスト用に維持する
- 任意銘柄追加時は `isNikkei225 = false` として扱う
- 銘柄コードの重複は ViewModel / Repository 側でも防ぐ
- Step 10 時点では銘柄コードの重複はアプリ側の Repository チェックで抑制する。将来マイグレーションや同期を行う場合は、SwiftData側の一意性制約、重複検出、統合方針を追加検討する
- 将来ユーザーアカウントを導入する場合は userId を追加する
- 削除は物理削除から始めてもよいが、将来同期する場合は archivedAt や deletedAt を検討する
- Step 4 では `WatchlistRepository` / `InMemoryWatchlistRepository` を用意し、SwiftDataや将来APIへ差し替えやすい保存境界を先に作る
- SwiftData化しても、銘柄マスタとウォッチリストは分離して扱う

## InvestmentMemo

InvestmentMemo は、銘柄ごとのユーザー入力メモを保持します。

Domainモデルの `InvestmentMemo` は通常の Swift 構造体として維持します。Step 10 時点では、SwiftData保存用の `InvestmentMemoRecord` を別に定義し、`SwiftDataInvestmentMemoRepository` が `InvestmentMemo` と `InvestmentMemoRecord` を変換します。確認メモは `stockCode` によって WatchlistItem と紐づけ、Repository 境界を通して取得、追加、更新、削除します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| stockCode | 対象銘柄コード |
| title | メモタイトル |
| body | メモ本文 |
| createdAt | 作成日時 |
| updatedAt | 更新日時 |

設計メモ:

- メモはユーザー自身の判断材料として扱う
- Step 6 ではタイトル空不可、本文空可とする
- `InvestmentMemoRepository` / `InMemoryInvestmentMemoRepository` を用意し、将来 SwiftData やバックエンドへ差し替えやすい保存境界を先に作る
- Step 10 ではアプリ本体の確認メモを `SwiftDataInvestmentMemoRepository` に差し替え、再起動後も保存されるようにする
- `InMemoryInvestmentMemoRepository` はPreviewとテスト用に維持する
- 将来、メモ種別、表示順、添付情報、watchlistItemId、serverId、deletedAt などを追加できる余地を残す
- 将来、ユーザーが入力した数値メモを AlertRule のしきい値として参照する場合も、アプリ側は売買判断として解釈しない
- アプリはメモ内容を売買推奨として解釈・表示しない

## AlertRule

AlertRule は、ユーザーが定義した条件を保持します。

Domainモデルの `AlertRule` は通常の Swift 構造体として維持します。Step 10 時点では、SwiftData保存用の `AlertRuleRecord` を別に定義し、`SwiftDataAlertRuleRepository` が `AlertRule` と `AlertRuleRecord` を変換します。ユーザー設定条件は `stockCode` によって WatchlistItem と紐づけ、Repository 境界を通して取得、追加、更新、削除します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| stockCode | 対象銘柄コード |
| name | 条件名 |
| metric | 対象指標 |
| comparisonOperator | 比較演算子 |
| thresholdValue | しきい値 |
| isEnabled | 有効フラグ |
| createdAt | 作成日時 |
| updatedAt | 更新日時 |

metricType の初期対応:

- currentPrice
- per
- pbr
- volume

後続対応:

- priceChangePercent
- volumeAverageRatio
- daysUntilEarnings
- targetPrice
- stopLossPrice
- movingAverageDeviation
- rsi
- macd

comparisonOperator の候補:

初期版で対応:

- greaterThan
- greaterThanOrEqual
- lessThan
- lessThanOrEqual
- equal
- notEqual

後続対応:

- withinDays
- ratioGreaterThanOrEqual

設計メモ:

- 初期版では、1つの AlertRule は1つの条件式だけを持つ
- 1つの WatchlistItem に対して複数の AlertRule を登録できる
- Step 7 では条件名空不可、しきい値は数値、しきい値は0以上とする
- `AlertRuleRepository` / `InMemoryAlertRuleRepository` を用意し、将来 SwiftData やバックエンドへ差し替えやすい保存境界を先に作る
- Step 8 時点では条件の登録、編集、削除、有効/無効切り替えに加えて、固定モック株価による条件評価と条件一致履歴作成までを実装している
- Step 10 ではアプリ本体のユーザー設定条件を `SwiftDataAlertRuleRepository` に差し替え、再起動後も保存されるようにする
- `AlertRuleRecord` では `metric` と `comparisonOperator` をRawValue文字列として保存する。不正なRawValueが保存されている場合は、クラッシュさせず復元できないRecordとして読み飛ばす
- `InMemoryAlertRuleRepository` はPreviewとテスト用に維持する
- 将来、複合条件にする場合は AlertRule を親にし、AlertConditionNode を追加する
- 対象指標と比較演算子を分離し、同じ比較ロジックを複数指標で使い回せるようにする
- 条件内容の表示文言は売買推奨に見えないようにする

## AlertMatchHistory

AlertMatchHistory は、条件一致の履歴を保持します。Step 8 では通知送信を行わず、銘柄詳細画面の条件一致履歴として表示します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| stockCode | 条件一致時点の銘柄コード |
| alertRuleId | 元になった条件ID |
| alertRuleName | 条件一致時点の条件名 |
| metric | 条件一致時点の対象指標 |
| comparisonOperator | 条件一致時点の比較演算子 |
| thresholdValue | 条件一致時点のしきい値 |
| observedValue | 条件一致時点の観測値 |
| matchedAt | 条件一致日時 |
| sourceName | 評価用データの取得元名 |

設計メモ:

- 条件変更後も過去履歴の意味が変わらないようにスナップショットを保存する
- 通知履歴は売買推奨履歴ではなく、条件一致履歴として扱う
- 同じ Snapshot 取得時刻と条件IDの組み合わせでは重複履歴を作らない
- Step 10 ではアプリ本体の条件一致履歴を `SwiftDataAlertMatchHistoryRepository` に差し替え、再起動後も保存されるようにする
- `AlertMatchHistoryRecord` では、条件名、対象指標、比較演算子、しきい値、観測値、データソースをスナップショットとして保存する
- `AlertMatchHistoryRecord` の対象指標または比較演算子RawValueが不正な場合は、クラッシュさせず復元できないRecordとして読み飛ばす
- `InMemoryAlertMatchHistoryRepository` はPreviewとテスト用に維持する
- 確認済みフラグや通知送信状態は、通知機能や全体履歴画面を追加する段階で検討する
- 将来バックエンド化する場合、履歴は監査的な意味を持つため変更を最小にする

## StockSnapshot

StockSnapshot は、条件判定に渡す評価用データです。SwiftDataで永続化するかどうかは初期実装時に判断しますが、AlertRuleEvaluator の入力として明確に定義します。

| 項目 | 内容 |
| --- | --- |
| stockCode | 銘柄コード |
| currentPrice | 現在値または入力株価 |
| per | PER |
| pbr | PBR |
| volume | 出来高 |
| capturedAt | 値を入力・取得した日時 |
| sourceName | manualInput、固定モック株価、externalApi、web、realtime などの取得元名 |

将来拡張候補:

| 項目 | 内容 |
| --- | --- |
| priceChangePercent | 前日比 |
| daysUntilEarnings | 決算日までの日数 |
| targetPrice | 目標株価 |
| stopLossPrice | 損切りライン |
| movingAverageDeviation | 移動平均線との差 |
| rsi | RSI |
| macd | MACD関連値 |

設計メモ:

- AlertRuleEvaluator は StockSnapshot を入力として受け取り、データ取得方法には依存しない
- 初期版では、手入力値またはモックデータから StockSnapshot を生成する
- 将来版では、外部API、Web取得、リアルタイムデータから StockSnapshot を生成する
- 欠損値がある場合、Evaluator は推測せず判定不能として扱う
- UI表示用データやAPIレスポンスを直接条件判定に渡さない

## ExternalStockSnapshotResponse

ExternalStockSnapshotResponse は、Step 12 で追加する外部APIレスポンス相当の中間DTOです。実際のAPIレスポンス形式に強く依存せず、外部データを `StockSnapshot` に変換する手前の共通形として扱います。

| 項目 | 内容 |
| --- | --- |
| stockCode | 銘柄コード。必須 |
| currentPrice | 現在値または終値相当。任意 |
| per | PER。任意 |
| pbr | PBR。任意 |
| volume | 出来高。任意 |
| capturedAt | 取得日時。任意 |
| sourceName | 取得元名。任意 |

設計メモ:

- `AlertRuleEvaluator` は `ExternalStockSnapshotResponse` を直接扱わない。
- `ExternalApiStockDataProvider` が `ExternalStockSnapshotResponse` を `StockSnapshot` へ変換する。
- currentPrice、per、pbr、volume がすべて nil の場合は、有効な `StockSnapshot` として扱わない。
- capturedAt が nil の場合は、変換時点の日時を `StockSnapshot.capturedAt` として使う。
- sourceName が nil または空の場合は「外部API疑似データ」を使う。
- 実際のAPI別レスポンスは、必要に応じてAPI固有DTOからこのDTOへ変換する。

## ManualStockSnapshotInput

ManualStockSnapshotInput は、銘柄ごとにユーザーが手入力した評価用データです。条件判定前に StockSnapshot へ変換し、AlertRuleEvaluator へ渡します。

| 項目 | 内容 |
| --- | --- |
| id | 手入力評価データID |
| stockCode | 銘柄コード |
| currentPrice | 現在値。任意入力 |
| per | PER。任意入力 |
| pbr | PBR。任意入力 |
| volume | 出来高。任意入力 |
| updatedAt | 入力または更新日時 |
| sourceName | データソース名。初期値は「手入力評価データ」 |

設計メモ:

- すべての指標は任意入力とし、空欄は nil として扱う
- currentPrice、per、pbr、volume がすべて nil の場合は、有効な手入力評価データなしとして扱う
- 全項目空欄の保存は許可せず、削除したい場合は削除操作を使う
- nil の指標を条件評価に使った場合、AlertRuleEvaluator は判定不能を返す
- 入力値は0以上の数値に制限する
- DomainモデルとSwiftData保存用Recordモデルは分ける
- Step 11 では `ManualStockSnapshotInputRecord` と `SwiftDataManualStockSnapshotInputRepository` を追加し、手入力評価データをSwiftDataへ保存する
- View は SwiftData の `ModelContext` を直接操作せず、`ManualStockSnapshotInputRepository` と `ManualStockSnapshotInputViewModel` 経由で保存・取得・削除を行う

## DataProvider相当の境界

DataProvider 相当の境界は、各データ取得元から StockSnapshot を生成する責務を持ちます。これは永続化モデルではなく、設計上の境界です。

初期版:

- ManualInputStockDataProvider
- MockStockDataProvider

Step 8 の実装:

- `StockDataProviding`
- `MockStockDataProvider`
- 固定モック株価の `sourceName` は「固定モック株価」
- 代表コードに対して `currentPrice`、PER、PBR、出来高を返せる構造を持つ
- 未定義銘柄コードでは Snapshot を返さず、評価結果は判定不能として扱う

Step 11 の実装:

- `MockStockDataValue` により、固定モック値として `currentPrice`、`per`、`pbr`、`volume` を保持できる
- 既存の `mockValues: [String: Double]` 形式も currentPrice 用の簡易指定として利用できる
- `ManualInputStockDataProvider` は、`ManualStockSnapshotInputRepository` から取得した手入力評価データを StockSnapshot へ変換する
- `ManualInputStockDataProvider` は、取得した手入力評価データの全項目が nil の場合は Snapshot を返さない
- `ExternalApiStockDataProvider` は外部API連携に向けたスタブとして用意し、Step 11 時点ではネットワーク通信を行わず Snapshot を返さない
- `FallbackStockDataProvider` は、現時点では有効な手入力評価データがある場合は手入力値を優先し、未登録または全項目空欄の場合は固定モック値を返す
- 将来の優先順位は、手入力評価データ、外部API取得値、開発用固定モック値の順とする
- 条件設定画面では `currentPrice`、`per`、`pbr`、`volume` を選択できる
- 選択した指標が StockSnapshot 内で nil の場合は判定不能として扱う
- AlertRuleEvaluator は引き続き StockSnapshot の `value(for:)` を通して対象指標値を取得し、DataProviderの種類には依存しない
- 外部API、手入力、リアルタイム取得を追加する場合も、まず StockSnapshot に変換してから評価する
- APIキー未設定、取得失敗、レート制限、欠損値はDataProvider層で検知し、ViewModel/UIでは中立的なエラーまたは判定不能として扱う

Step 12 の実装:

- `ExternalStockSnapshotResponse` を追加し、外部APIレスポンス相当の値を `StockSnapshot` に変換できるようにする
- `ExternalApiStockDataProvider` はネットワーク通信を行わず、ローカルに渡された疑似レスポンスから `StockSnapshot` を返す
- `CompositeStockDataProvider` は `ManualInputStockDataProvider`、`ExternalApiStockDataProvider`、`MockStockDataProvider` を順番に試す
- 有効な手入力評価データがある場合は手入力値を優先し、なければ外部API疑似データ、固定モック値の順にフォールバックする
- 全指標が nil の外部API疑似レスポンスは有効な `StockSnapshot` として扱わず、次のProviderへフォールバックする
- 実通信、APIキー保存、認証、レート制限対応、キャッシュ、バックグラウンド更新は後続対応にする

将来版:

- ExternalApiStockDataProvider
- WebStockDataProvider
- RealtimeStockDataProvider

責務:

- データ取得元の違いを吸収する
- 取得値や入力値を StockSnapshot に変換する
- 欠損値や取得失敗を AlertRuleEvaluator に直接漏らさず、判定不能として扱える形にする
- AlertRuleEvaluator を外部API、画面入力、モックデータから独立させる

## SwiftDataでのモデル案

SwiftData では、Domainモデルとは別にRecordモデルを永続化対象として定義します。実装時の方針は以下です。

- StockMaster と WatchlistItem は分離する
- WatchlistItem から StockMaster を参照する
- InvestmentMemo は WatchlistItem に対して複数持てる
- AlertRule は WatchlistItem に対して複数持てる
- AlertMatchHistory は WatchlistItem と AlertRule に関連づく
- StockSnapshot は初期版では一時データでもよいが、将来は取得履歴や日足データとして保存対象にできる
- enum 相当の値は、初期版では文字列として保存すると移行しやすい
- 作成日時と更新日時を各モデルに持たせる
- 将来の同期に備え、serverId や deletedAt を追加できる余地を残す

Step 9 の実装:

- `WatchlistItemRecord`
- `InvestmentMemoRecord`
- `AlertRuleRecord`
- `AlertMatchHistoryRecord`
- `SwiftDataWatchlistRepository`

Step 10 の実装:

- `SwiftDataInvestmentMemoRepository`
- `SwiftDataAlertRuleRepository`
- `SwiftDataAlertMatchHistoryRepository`
- `InvestmentMemoRecord`、`AlertRuleRecord`、`AlertMatchHistoryRecord` とDomainモデルの相互変換

Step 10 時点で、ウォッチリスト、確認メモ、ユーザー設定条件、条件一致履歴はSwiftData Repositoryへ差し替え済みです。`InMemory...Repository` はPreviewとテスト用に維持します。

永続化品質改善では、SwiftData Repository の取得処理を `FetchDescriptor` の predicate / sort に寄せ、銘柄コードによる絞り込みや日時順の並び替えをSwiftData側で行うようにします。読み取り失敗時は `RepositoryReadStatusProviding` を通してViewModelへ中立的なエラーメッセージを渡し、画面では未登録状態と読み込み失敗を区別します。

delete系は既存プロトコルの戻り値を大きく変えず、Boolの失敗をViewModel側でエラーメッセージとして保持します。条件一致履歴の全削除は現時点では戻り値を持たないため、失敗理由の詳細表示や例外伝播は後続の設計課題として残します。

Step 11 の実装:

- `ManualStockSnapshotInputRecord`
- `SwiftDataManualStockSnapshotInputRepository`
- `ManualStockSnapshotInputRecord` と `ManualStockSnapshotInput` の相互変換

Step 11 時点で、手入力評価データもSwiftData Repositoryへ保存します。現在値、PER、PBR、出来高はいずれも任意入力で、未入力の指標は判定不能として扱います。

関連の考え方:

| 親 | 子 | 関係 |
| --- | --- | --- |
| StockMaster | WatchlistItem | 1対多の余地あり |
| WatchlistItem | InvestmentMemo | 1対多 |
| WatchlistItem | AlertRule | 1対多 |
| WatchlistItem | AlertMatchHistory | 1対多 |
| AlertRule | AlertMatchHistory | 1対多 |

初期版ではユーザーアカウントを持たないため、すべて単一ユーザーのローカルデータとして扱います。

## 将来バックエンド化する場合のDB設計に繋げやすい構成案

将来 PostgreSQL などのDBに移行する場合は、以下のテーブル構成に繋げやすいです。

- stock_masters
- users
- watchlist_items
- investment_memos
- alert_rules
- alert_condition_nodes
- alert_match_histories
- stock_snapshots
- stock_data_sources

バックエンド化時に追加を検討する項目:

- user_id
- server_id
- created_at
- updated_at
- deleted_at
- sync_version
- data_source
- source_updated_at

StockSnapshot の考え方:

- 初期版では手入力値またはモック値として扱う
- 将来は外部APIから取得した株価、PER、PBR、出来高、決算日などを保持する
- 条件判定は StockSnapshot を入力として実行する
- UIやAPIレスポンスの形式に依存しない評価用データとして設計する
- DataProvider 相当の境界により、手入力、モック、外部API、Web取得、リアルタイムデータを差し替えやすくする

バックエンド化しても、アプリの本質は「ユーザー定義条件に一致した事実を通知・記録すること」です。DB設計でも、売買推奨や利益保証を意味するフィールド名や文言は避けます。
