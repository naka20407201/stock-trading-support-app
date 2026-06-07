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
- 将来ユーザーアカウントを導入する場合は userId を追加する
- 削除は物理削除から始めてもよいが、将来同期する場合は archivedAt や deletedAt を検討する
- Step 4 では `WatchlistRepository` / `InMemoryWatchlistRepository` を用意し、SwiftDataや将来APIへ差し替えやすい保存境界を先に作る
- SwiftData化しても、銘柄マスタとウォッチリストは分離して扱う

## InvestmentMemo

InvestmentMemo は、銘柄ごとのユーザー入力メモを保持します。

Step 6 時点では、SwiftData 永続化モデルではなく通常の Swift 構造体として実装します。確認メモは `stockCode` によって WatchlistItem と紐づけ、Repository 境界を通して取得、追加、更新、削除します。

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
- 将来、メモ種別、表示順、添付情報、watchlistItemId、serverId、deletedAt などを追加できる余地を残す
- 将来、ユーザーが入力した数値メモを AlertRule のしきい値として参照する場合も、アプリ側は売買判断として解釈しない
- アプリはメモ内容を売買推奨として解釈・表示しない

## AlertRule

AlertRule は、ユーザーが定義した条件を保持します。

Step 7 時点では、SwiftData 永続化モデルではなく通常の Swift 構造体として実装します。ユーザー設定条件は `stockCode` によって WatchlistItem と紐づけ、Repository 境界を通して取得、追加、更新、削除します。

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

metricType の候補:

初期版の最優先:

- currentPrice

初期版で手入力・モック値として対応余地を残す:

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

## DataProvider相当の境界

DataProvider 相当の境界は、各データ取得元から StockSnapshot を生成する責務を持ちます。これは永続化モデルではなく、設計上の境界です。

初期版:

- ManualInputStockDataProvider
- MockStockDataProvider

Step 8 の実装:

- `StockDataProviding`
- `MockStockDataProvider`
- 固定モック株価の `sourceName` は「固定モック株価」
- 代表コードに対して `currentPrice` のみを返し、PER、PBR、出来高は nil のまま扱う
- 未定義銘柄コードでは Snapshot を返さず、評価結果は判定不能として扱う

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

Step 9 でRepository差し替えまで完了しているのは `WatchlistItemRecord` のみです。`InvestmentMemoRecord`、`AlertRuleRecord`、`AlertMatchHistoryRecord` は後続StepでRepositoryを差し替えるための保存用Recordとして先に用意しています。

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
