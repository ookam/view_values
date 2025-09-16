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
