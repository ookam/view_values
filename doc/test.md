了解。KISS 版 README の仕様を満たすための**網羅テスト・チェックリスト**をまとめました。これらが全部グリーンになればリリース判定 OK です。

# テストチェックリスト

## 1) ビルド／基本アクセス

- [ ] `build_view_values` が `@view_values` を生成する（nil でない）。
- [ ] `data` に渡した **symbol / string** キーどちらも dot で参照可能（`post`, `user`）。
- [ ] 未定義キーは `NoMethodError` を送出（メッセージにキー名が含まれる）。
- [ ] `@view_values` は `respond_to?` が root キーに対して `true` を返す。

## 2) ヘルパ注入（helpers:）

- [ ] `helpers: %i[current_user]` を指定すると、ビューで `@view_values.current_user` が呼べる。
- [ ] ヘルパは**遅延評価**：`build_view_values` 後に `current_user` が変化しても、ビュー時点の値が反映される。
- [ ] `data` と `helpers` が衝突した場合、**data が優先**される。
- [ ] `helpers` に存在しないメソッド名を渡しても例外にならず、アクセス時に `NoMethodError`（＝メソッド未生成のため）になる。

## 3) dot-only（\[] 禁止の挙動）

- [ ] `@view_values[:user]` は `NoMethodError`（`[]` 未定義）になる。
- [ ] `@view_values.user` は成功する（dot 専用の確認）。

## 4) 不変性・再代入

- [ ] `@view_values` 自体に公開 setter が無い（root キーの再定義不可）。
- [ ] `build_view_values` を**複数回**呼ぶと、最後に呼んだ内容で **上書き** される（想定どおりに最新が優先）。

## 5) ビュー統合（Controller + View の実レンダリング）

- [ ] ERB テンプレを実際に render し、`@view_values.post.title` 等が期待文字列を含む。
- [ ] `NoMethodError` を起こすケース（未定義キー参照）でテンプレートレンダが失敗する。
- [ ] `helpers` で注入した `is_login?` が条件分岐に使える（`true/false` で表示切替）。

## 6) Provider の mixin（include の効果）

- [ ] `ApplicationController` に `include ViewValues::Provider` すると、各コントローラで `build_view_values` が使える。
- [ ] ビューから `@view_values` が参照できる。
- [ ] （任意）`helper_method :view_values` により、`view_values` メソッド経由でも同じオブジェクトが取得できる。

## 7) 設定（instance_var_name）

- [ ] `ViewValues.configure { |c| c.instance_var_name = :vv }` で、ビューから `@vv` で参照できる。
- [ ] `@view_values` は `nil` のまま／もしくは設定に応じた方のみセットされる（片方だけ有効）。
- [ ] `build_view_values` の呼び出しは変更不要（内部的に正しいインスタンス変数に格納される）。

## 8) 優先順位 & 衝突

- [ ] `data: { current_user: :x }` と `helpers: %i[current_user]` を同時指定したとき、`@view_values.current_user` は **:x**（data 優先）。
- [ ] `helpers` で同名を複数指定しても（順序を変えて）結果は不変（重複の影響なし）。

## 9) キー可視化（任意）

- [ ] `@view_values.keys` が root キー一覧を返す（`%i[post user is_login? current_user]` 等）。
- [ ] `@view_values.empty?` の真偽が想定どおり（データ未指定時は `true` など、実装が提供するメソッドに合わせる）。

## 10) 例外メッセージ（DX）

- [ ] 未定義キーの `NoMethodError` メッセージに **undefined root key 'xxx'** のようなキー名が含まれる（README の期待と一致）。
- [ ] `[]` 使用時の `NoMethodError` メッセージが「dot access を使う」ことを示唆する文面（あれば）。

## 11) 文字エンコーディング / I18n（軽く）

- [ ] 日本語タイトル等を `@view_values` 経由でレンダしても文字化けしない（UTF-8 想定で OK）。

## 12) スレッド／複数リクエスト（軽い健全性）

- [ ] 並行に 2 つのコントローラインスタンスで `build_view_values` を呼んだとき、互いの `@view_values` が**干渉しない**（リークしない）。

## 13) 互換（最低限）

- [ ] Rails 6.1 / 7.x の **最低 1 つずつ**で同テストが通る（Appraisal などでマトリクス運用 or CI ジョブ分割）。
- [ ] Ruby のサポートバージョン（例: 3.1/3.2/3.3）でもテストパス。

## 14) ドキュメント整合

- [ ] README のサンプルコードがそのままコピペでテスト内でも動く（サンプルの E2E）。

---

### 追加で入れると安心な「バグ回避系」小テスト（任意）

- [ ] `helpers:` で **private メソッド**を指定した場合：`public_send` なら失敗、`send` なら成功—実装に合わせて期待を固定（README に注記しても良い）。
- [ ] `helpers:` のラムダ生成が**毎回評価**か**一度だけ評価**か（仕様の明確化に沿った期待：README は「遅延評価（ビュー時）」なので毎回=OK）。
- [ ] `data` に `nil` を入れたキーも dot で参照できる（nil を返す）。

---

## 参考：spec 構成例

- `spec/view_values/provider_spec.rb`（mixin & instance var name & overwrite）
- `spec/view_values/helpers_spec.rb`（helpers 遅延評価・優先順位・未定義時の挙動）
- `spec/integration/rendering_spec.rb`（Controller + View の実レンダ）
- `spec/view_values/dot_only_spec.rb`（`[]` 禁止/NoMethodError）
- `spec/compat/rails61_spec.rb` / `rails7_spec.rb`（CI で分岐）

---

これで“機能要件”と“README の約束”をすべて検証できます。
必要なら、上記チェックリストからそのまま **RSpec の雛形**を起こした版も即座に用意します。
