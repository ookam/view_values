# frozen_string_literal: true

module ViewValues
  class Config
    # Symbol without leading @ (e.g., :view_values, :vv)
    attr_accessor :instance_var_name

    def initialize
      @instance_var_name = :view_values
    end
  end

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end

    # String like "@view_values" or "@vv"
    def instance_variable_name
      "@#{config.instance_var_name}"
    end
  end
end
