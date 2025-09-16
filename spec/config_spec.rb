# frozen_string_literal: true

RSpec.describe ViewValues::Config do
  around do |ex|
    orig = ViewValues.config.instance_var_name
    begin
      ex.run
    ensure
      ViewValues.config.instance_var_name = orig
    end
  end

  it "defaults to :view_values and can be changed" do
    expect(ViewValues.instance_variable_name).to eq "@view_values"
    ViewValues.configure { |c| c.instance_var_name = :vv }
    expect(ViewValues.instance_variable_name).to eq "@vv"
  end
end

RSpec.describe ViewValues::Provider do
  around do |ex|
    orig = ViewValues.config.instance_var_name
    begin
      ViewValues.config.instance_var_name = :vv
      ex.run
    ensure
      ViewValues.config.instance_var_name = orig
    end
  end

  let(:controller_class) do
    Class.new do
      include ViewValues::Provider
      def self.helper_method(*) ; end
    end
  end

  it "assigns to configured instance variable name" do
    c = controller_class.new
    c.build_view_values({ a: 1 })
    expect(c.instance_variable_defined?(:@vv)).to be true
    expect(c.instance_variable_get(:@vv).a).to eq 1
  end
end
