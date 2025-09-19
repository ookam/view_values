# frozen_string_literal: true

require 'active_support/core_ext/hash/keys'

module ViewValues
  class Context
    def self.build(controller, data = {}, helpers: [])
      new(controller, data, helpers: helpers)
    end

    def initialize(controller, data, helpers:)
      @controller = controller
      @data = data.to_h.symbolize_keys

      helpers.map { |m| m.to_sym }.uniq.each do |sym|

        # data と helpers の同名衝突は即時エラー
        if @data.key?(sym)
          raise ArgumentError, "conflicting key '#{sym}' given in both data and helpers for #{ViewValues.instance_variable_name}"
        end

        # ビルド時に存在検証（実際の呼び出しは行わない）
        exists =
          @controller.respond_to?(sym, true) ||
          (@controller.respond_to?(:helpers) && @controller.helpers.respond_to?(sym, true)) ||
          (@controller.respond_to?(:view_context) && @controller.view_context.respond_to?(sym, true))

        unless exists
          raise NoMethodError, "undefined helper '#{sym}' for #{ViewValues.instance_variable_name}: not found on controller, helpers, or view_context"
        end

        binder = lambda do
          if @controller.respond_to?(sym)
            return @controller.public_send(sym)
          end

          if @controller.respond_to?(:helpers)
            begin
              return @controller.helpers.public_send(sym)
            rescue NoMethodError, NameError
              # try next
            end
          end

          if @controller.respond_to?(:view_context)
            begin
              return @controller.view_context.public_send(sym)
            rescue NoMethodError, NameError
              # fallthrough
            end
          end

          raise NoMethodError, "undefined helper '#{sym}' for #{ViewValues.instance_variable_name}: not found on controller, helpers, or view_context"
        end

        @data[sym] = binder
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

    def empty? = @data.empty?

    def respond_to_missing?(name, _ = false)
      @data.key?(name.to_sym) || super
    end

    def method_missing(name, *args, &)
      return super unless args.empty? && !block_given?

      raise NoMethodError, "undefined root key '#{name}' for #{ViewValues.instance_variable_name}"
    end
  end
end
