# frozen_string_literal: true

require 'active_support/concern'

module ViewValues
  module Provider
    extend ActiveSupport::Concern

    included do
      helper_method :view_values if respond_to?(:helper_method)
    end

    # KISS：これ一発でOK（@view_values に代入＆返す）
    def build_view_values(data = {}, helpers: [])
      ctx = ViewValues::Context.build(self, data, helpers: helpers)
      instance_variable_set(ViewValues.instance_variable_name, ctx)
      ctx
    end

    # ビューから `view_values` でも参照できるように
    def view_values
      instance_variable_get(ViewValues.instance_variable_name)
    end
  end
end
