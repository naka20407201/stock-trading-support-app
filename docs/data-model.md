# データモデル設計

## 基本方針

初期版では SwiftData によるローカル保存を想定します。将来バックエンド化しやすくするため、銘柄マスタ、ウォッチリスト、投資メモ、アラート条件、通知履歴を分離します。

中心モデルは以下です。

- StockMaster
- WatchlistItem
- InvestmentMemo
- AlertRule
- AlertHistory

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

## WatchlistItem

WatchlistItem は、ユーザーが監視対象として選んだ銘柄を表します。StockMaster とは分離し、ユーザー固有の状態を持ちます。

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

設計メモ:

- 同じ StockMaster を、ユーザーがウォッチリストに追加した状態として扱う
- 将来ユーザーアカウントを導入する場合は userId を追加する
- 削除は物理削除から始めてもよいが、将来同期する場合は archivedAt や deletedAt を検討する

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

- currentPrice
- priceChangePercent
- per
- pbr
- volume
- volumeAverageRatio
- daysUntilEarnings
- targetPriceReached
- stopLossReached
- movingAverageDeviation
- rsi
- macd

comparisonOperator の候補:

- greaterThan
- greaterThanOrEqual
- lessThan
- lessThanOrEqual
- equal
- notEqual
- withinDays
- ratioGreaterThanOrEqual

設計メモ:

- 初期版では単一条件を扱う
- 将来、複合条件にする場合は AlertRule を親にし、AlertConditionNode を追加する
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

## SwiftDataでのモデル案

SwiftData では、上記モデルを永続化対象として定義します。実装時の方針は以下です。

- StockMaster と WatchlistItem は分離する
- WatchlistItem から StockMaster を参照する
- InvestmentMemo は WatchlistItem に対して原則1つ持つ
- AlertRule は WatchlistItem に対して複数持てる
- AlertHistory は WatchlistItem と AlertRule に関連づく
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

バックエンド化しても、アプリの本質は「ユーザー定義条件に一致した事実を通知・記録すること」です。DB設計でも、売買推奨や利益保証を意味するフィールド名や文言は避けます。
