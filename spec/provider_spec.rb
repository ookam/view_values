# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/module/attribute_accessors"

RSpec.describe ViewValues::Provider do
  let(:controller_class) do
    Class.new do
      include ViewValues::Provider

      # simulate Rails' helper_method availability (noop)
      def self.helper_method(*) ; end

      def current_user = OpenStruct.new(name: "Bob")
      def is_login? = true
    end
  end

  let(:controller) { controller_class.new }

  it "builds and assigns @view_values" do
    controller.build_view_values({ post: :p }, helpers: %i[current_user is_login?])
    vv = controller.view_values
    expect(vv.post).to eq :p
    expect(vv.current_user.name).to eq "Bob"
    expect(vv.is_login?).to be true
  end
end
