はい、その設計で OK です。**`ApplicationController` に mixin を `include` して、コントローラ自身を暗黙にキャプチャ**すれば、`current_controller` を明示的に渡す必要はありません。KISS で最小構成のサンプルを置きます。

```rb
# lib/view_values/context.rb
# frozen_string_literal: true
module ViewValues
  class Context
    def self.build(controller, data = {}, helpers: [])
      new(controller, data, helpers: helpers)
    end

    def initialize(controller, data, helpers:)
      @controller = controller
      @data = data.to_h.symbolize_keys

      helpers.each do |m|
        sym = m.to_sym
        @data[sym] ||= -> { @controller.public_send(sym) }
      end

      # root だけ dot アクセス
      @data.each_key do |k|
        define_singleton_method(k) do
          v = @data[k]
          v.respond_to?(:call) ? v.call : v
        end
      end

      freeze
    end

    def keys = @data.keys

    def respond_to_missing?(name, _ = false)
      @data.key?(name.to_sym) || super
    end

    def method_missing(name, *args, &)
      return super unless args.empty? && !block_given?
      raise NoMethodError, "undefined root key '#{name}' for @view_values"
    end
  end
end
```

```rb
# lib/view_values/provider.rb
# frozen_string_literal: true
module ViewValues
  module Provider
    extend ActiveSupport::Concern

    included do
      helper_method :view_values if respond_to?(:helper_method)
    end

    # KISS：これ一発でOK（@view_values に代入＆返す）
    def build_view_values(data = {}, helpers: [])
      @view_values = ViewValues::Context.build(self, data, helpers: helpers)
    end

    # ビューから `view_values` でも参照できるように
    def view_values
      @view_values
    end
  end
end
```

```rb
# lib/view_values/railtie.rb（任意）
# frozen_string_literal: true
require "rails/railtie"
module ViewValues
  class Railtie < ::Rails::Railtie
    initializer "view_values.include_provider" do
      ActiveSupport.on_load(:action_controller) do
        include ViewValues::Provider
      end
    end
  end
end
```

### 使い方（最小）

```rb
# application_controller.rb
class ApplicationController < ActionController::Base
  # Railtieがあれば不要だが、明示したいなら：
  include ViewValues::Provider
end
```

```rb
# posts_controller.rb
class PostsController < ApplicationController
  def show
    post = Post.find(params[:id])
    build_view_values(
      { post: post, user: current_user, is_login?: current_user.present? },
      helpers: %i[current_user is_login?] # 好きなだけ列挙（存在すれば呼べる）
    )
  end
end
```

```erb
<!-- app/views/posts/show.html.erb -->
<h1><%= @view_values.post.title %></h1>
<p><%= @view_values.current_user.name %></p>
<% if @view_values.is_login? %>ログイン中<% end %>
```

---

## これで満たせること

- **KISS**：`build_view_values` で **root 一括注入**＋**helpers バインド**だけ。
- **明示性**：ビューの入口は常に `@view_values`。root キーが無ければ `NoMethodError`。
- **状態管理なし**：`Thread.current` 不要。**include だけ**でコントローラを捕まえる。
- **拡張余地**：必要なら後から `helpers: true` の自動列挙や `strict/dev警告` を足せるが、v1 では不要。

> 要望どおり、**「@view_values = ViewValues.build({user: @user}, helpers: %w(current_user is_login?))」相当**を、明示渡し不要で実現しています（`build_view_values` ひと呼び）。これ以上は足さないのが KISS です。
