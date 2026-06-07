# データモデル設計

## 基本方針

初期版では SwiftData によるローカル保存を想定します。将来バックエンド化しやすくするため、銘柄マスタ、ウォッチリスト、投資メモ、アラート条件、通知履歴を分離します。

中心モデルは以下です。

- StockMaster
- WatchlistItem
- InvestmentMemo
- AlertRule
- AlertHistory
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

Step 4 / Step 5 時点では、SwiftData 永続化モデルではなく通常の Swift 構造体として実装します。初期実装の `WatchlistItem` は、ウォッチリスト表示、銘柄詳細への遷移、任意銘柄追加の受け皿として以下を保持します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| code | 銘柄コード |
| name | 銘柄名 |
| market | 市場区分 |
| industry | 業種 |
| isNikkei225 | 日経225標準候補かどうか |
| createdAt | 作成日時 |

将来 SwiftData 化する場合は、以下のように StockMaster への参照や監視状態、表示順などを追加・移行します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| stockMasterId | 対象銘柄マスタID |
| isMonitoring | 監視中フラグ |
| note | ウォッチリスト用の短いメモ |
| displayOrder | 表示順 |
| addedAt | 追加日時 |
| createdAt | 作成日時 |
| updatedAt | 更新日時 |

Step 4 の初期実装では、SwiftData永続化モデルではなく通常のSwift構造体として `WatchlistItem` を作成します。初期構造体では、今後の画面確認とRepository境界作成を優先し、以下を保持します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| code | 銘柄コード |
| name | 銘柄名 |
| market | 市場区分 |
| industry | 業種 |
| isNikkei225 | 日経225標準候補かどうか |
| createdAt | 作成日時 |

設計メモ:

- 同じ StockMaster を、ユーザーがウォッチリストに追加した状態として扱う
- Step 5 時点では `WatchlistViewModel` が `WatchlistRepository` を利用し、WatchlistView と AddStockView で同じウォッチリスト状態を共有する
- 初期版では `InMemoryWatchlistRepository` を利用し、SwiftData による本格永続化は後続対応にする
- 任意銘柄追加時は `isNikkei225 = false` として扱う
- 銘柄コードの重複は ViewModel / Repository 側でも防ぐ
- 将来ユーザーアカウントを導入する場合は userId を追加する
- 削除は物理削除から始めてもよいが、将来同期する場合は archivedAt や deletedAt を検討する
- Step 4 では `WatchlistRepository` / `InMemoryWatchlistRepository` を用意し、SwiftDataや将来APIへ差し替えやすい保存境界を先に作る
- InMemoryWatchlistRepository は開発用の一時実装であり、日経225候補からの追加UIや本格永続化は後続Stepで実装する

## InvestmentMemo

InvestmentMemo は、銘柄ごとのユーザー入力メモを保持します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| watchlistItemId | 対象ウォッチリスト項目ID |
| buyReason | 買いたい理由 |
| sellCondition | 売る条件 |
| stopLossCondition | 損切り条件 |
| targetPrice | 目標株価 |
| stopLossPrice | 損切りライン |
| cautionNote | 注意点 |
| preEarningsMemo | 決算前メモ |
| freeMemo | 自由メモ |
| createdAt | 作成日時 |
| updatedAt | 更新日時 |

設計メモ:

- メモはユーザー自身の判断材料として扱う
- 目標株価や損切りラインは、AlertRule のしきい値として参照できる可能性がある
- アプリはメモ内容を売買推奨として解釈・表示しない

## AlertRule

AlertRule は、ユーザーが定義した条件を保持します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| watchlistItemId | 対象ウォッチリスト項目ID |
| name | 条件名 |
| metricType | 対象指標 |
| comparisonOperator | 比較演算子 |
| thresholdValue | しきい値 |
| thresholdUnit | 円、%、倍、日など |
| isEnabled | 有効フラグ |
| memo | 条件メモ |
| lastEvaluatedAt | 最終判定日時 |
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
- 将来、複合条件にする場合は AlertRule を親にし、AlertConditionNode を追加する
- 対象指標と比較演算子を分離し、同じ比較ロジックを複数指標で使い回せるようにする
- 条件内容の表示文言は売買推奨に見えないようにする

## AlertHistory

AlertHistory は、条件一致の履歴を保持します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID |
| watchlistItemId | 対象ウォッチリスト項目ID |
| alertRuleId | 元になった条件ID |
| stockCodeSnapshot | 条件一致時点の銘柄コード |
| stockNameSnapshot | 条件一致時点の銘柄名 |
| ruleNameSnapshot | 条件一致時点の条件名 |
| ruleDescriptionSnapshot | 条件一致時点の条件内容 |
| metricTypeSnapshot | 条件一致時点の対象指標 |
| operatorSnapshot | 条件一致時点の比較演算子 |
| thresholdValueSnapshot | 条件一致時点のしきい値 |
| actualValueSnapshot | 条件一致時点の実値 |
| matchedAt | 条件一致日時 |
| isRead | ユーザーが確認済みかどうか |
| notificationStatus | 通知状態 |
| createdAt | 作成日時 |

設計メモ:

- 条件変更後も過去履歴の意味が変わらないようにスナップショットを保存する
- 通知履歴は売買推奨履歴ではなく、条件一致履歴として扱う
- 将来バックエンド化する場合、履歴は監査的な意味を持つため変更を最小にする

## StockSnapshot

StockSnapshot は、条件判定に渡す評価用データです。SwiftDataで永続化するかどうかは初期実装時に判断しますが、AlertRuleEvaluator の入力として明確に定義します。

| 項目 | 内容 |
| --- | --- |
| id | ローカルID。永続化しない場合は一時IDでもよい |
| stockMasterId | 対象銘柄マスタID |
| stockCode | 銘柄コード |
| capturedAt | 値を入力・取得した日時 |
| dataSource | manualInput、mock、externalApi、web、realtime など |
| currentPrice | 現在値または入力株価 |
| per | PER |
| pbr | PBR |
| volume | 出来高 |
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

SwiftData では、上記モデルを永続化対象として定義します。実装時の方針は以下です。

- StockMaster と WatchlistItem は分離する
- WatchlistItem から StockMaster を参照する
- InvestmentMemo は WatchlistItem に対して原則1つ持つ
- AlertRule は WatchlistItem に対して複数持てる
- AlertHistory は WatchlistItem と AlertRule に関連づく
- StockSnapshot は初期版では一時データでもよいが、将来は取得履歴や日足データとして保存対象にできる
- enum 相当の値は、初期版では文字列として保存すると移行しやすい
- 作成日時と更新日時を各モデルに持たせる
- 将来の同期に備え、serverId や deletedAt を追加できる余地を残す

関連の考え方:

| 親 | 子 | 関係 |
| --- | --- | --- |
| StockMaster | WatchlistItem | 1対多の余地あり |
| WatchlistItem | InvestmentMemo | 1対1 |
| WatchlistItem | AlertRule | 1対多 |
| WatchlistItem | AlertHistory | 1対多 |
| AlertRule | AlertHistory | 1対多 |

初期版ではユーザーアカウントを持たないため、すべて単一ユーザーのローカルデータとして扱います。

## 将来バックエンド化する場合のDB設計に繋げやすい構成案

将来 PostgreSQL などのDBに移行する場合は、以下のテーブル構成に繋げやすいです。

- stock_masters
- users
- watchlist_items
- investment_memos
- alert_rules
- alert_condition_nodes
- alert_histories
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
