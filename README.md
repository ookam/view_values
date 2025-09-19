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

---

MIT License
