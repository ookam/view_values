# 注意

これは個人的に使っている gem です。ノーサポート、ノー後方互換性なのでもし使いたい人がいたら fork をおすすめします。

# view_values

KISS な Rails 用ビュー値コンテナ。コントローラを暗黙にキャプチャして、ビューで `@view_values` から値やヘルパを安全に参照できます。

## インストール

Gemfile に追加:

```rb
gem "view_values"
```

Bundler:

```bash
bundle install
```

## 使い方

コントローラに Provider を mixin（自動 include はしません）

```rb
class ApplicationController < ActionController::Base
	include ViewValues::Provider
end
```

アクションで `build_view_values` を呼ぶだけ:

```rb
class PostsController < ApplicationController
	def show
		post = Post.find(params[:id])
		build_view_values(
			{ post: post, user: current_user, is_login?: current_user.present? },
			helpers: %i[current_user is_login?]
		)
	end
end
```

ビューで参照:

```erb
<h1><%= @view_values.post.title %></h1>
<p><%= @view_values.current_user.name %></p>
<% if @view_values.is_login? %>ログイン中<% end %>
```

### 設定（任意）

`config/initializers/view_values.rb` などで、インスタンス変数名を変更できます（デフォルトは `@view_values`）。

```rb
ViewValues.configure do |c|
	c.instance_var_name = :vv # => ビューでは @vv で参照可能 / デフォルトは :view_values
end
```

以降、コントローラからは同様に `build_view_values` を呼ぶだけで、ビューでは `@vv` で参照できます。

```erb
<%= @vv.post.title %>
```

### 仕様のポイント

- `build_view_values(data, helpers:)` はコントローラ自身を暗黙にキャプチャ
- `data` のキーは `symbolize_keys` 済み。キーは dot アクセスのみ可能
- `helpers:` に列挙したメソッドは遅延評価でバインド
- `helpers:` で指定したメソッドはビルド時に存在検証（controller/helpers/view_context）
- `data` と `helpers` に同名キーがある場合はビルド時に例外を送出（衝突の早期検知）
- 未定義キーは `NoMethodError` を送出（誤字に強い）

### 動作環境

Rails 6.1 / 7.x で動作確認済み。

### 制約

- ビューからは dot アクセスのみ可能です（`@view_values.user`）。
  `@view_values[:user]` のような Hash アクセスはできません。
- `helpers:` に指定したメソッドは遅延評価され、ビュー描画時に呼ばれます。
  例: `current_user` を指定すれば、ビュー時点のログイン状態に応じた値になります。

## 開発

```bash
bundle exec rspec      # テスト
bundle exec rubocop    # 静的解析
bundle exec rake       # デフォルトは spec
```

## CLI チェック

プロジェクト全体を静的に走査し、各コントローラのアクションで宣言したキー（`build_view_values` の data/`helpers:`）と、ビューで実際に使っているキーが整合しているかをチェックできます。

実行例:

```bash
bundle exec view_values check
```

デフォルト動作:

- 未宣言の使用はエラー（missing）
- 宣言されているが未使用のキーもエラー（unused）

オプション:

- `--root=PATH`: 解析するプロジェクトのルート（デフォルト: カレント）
- `--instance-var=name`: インスタンス変数名（デフォルト: `view_values` → `@view_values`）
- `--check-unused`: 互換目的（デフォルトで未使用もエラー）
- `--include=GLOB`: 対象コントローラをグロブで絞り込み
- `--only-action=NAME`: 単一アクション（メソッド名）に限定してチェック

#### チェックを丸ごとスキップしたいとき

アクションやビューに ` skip:view_values` という文字列が入っていれば、その単位の検証を丸ごと飛ばします。

```rb
def draft
	# skip:view_values
	build_view_values({})
end
```

```erb
<!-- skip:view_values -->
```

仕様/制約:

- ビューの実使用は `@<name>.key` の正規表現で抽出（`.try/.send/.public_send` は除外）。
- コメントでの明示許可: `<%# use: @view_values.user, @view_values.post.title %>`（ネストはルートキーのみ判定）
- パーシャル/レイアウトの追跡は未対応（将来拡張）。

備考:

- `build_view_values` が複数行でも解析されます。
- `helpers:` は `%i[...]` / `%I[...]` / `[:sym, 'str']` に対応。
- `data` は `{'str' => 1, sym: 2}` のようなキーも抽出対象（ビュー側は `@view_values.str` / `@view_values.sym`）。

---

MIT License
