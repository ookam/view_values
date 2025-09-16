# frozen_string_literal: true

require "ostruct"

RSpec.describe ViewValues::Context do
  let(:controller) do
    Class.new do
      def current_user = OpenStruct.new(name: "Alice")
      def is_login? = true
    end.new
  end

  it "symbolizes and exposes data keys via methods" do
    ctx = described_class.build(controller, { "post" => 1, user: 2 })
    expect(ctx.post).to eq 1
    expect(ctx.user).to eq 2
    expect(ctx.keys).to include(:post, :user)
  end

  it "binds helper methods lazily" do
    ctx = described_class.build(controller, {}, helpers: %i[current_user is_login?])
    expect(ctx.current_user.name).to eq "Alice"
    expect(ctx.is_login?).to be true
  end

  it "raises NoMethodError for unknown root keys" do
    ctx = described_class.build(controller, {})
    expect { ctx.unknown }.to raise_error(NoMethodError, /undefined root key 'unknown'/)
  end
end
