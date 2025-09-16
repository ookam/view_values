# frozen_string_literal: true

RSpec.describe ViewValues::Context do
  let(:controller) { Object.new }

  it "prefers explicit data over helper method with same name" do
    ctx = described_class.build(controller, { current_user: :explicit }, helpers: %i[current_user])
    expect(ctx.current_user).to eq :explicit
  end

  it "responds to defined keys and not to others" do
    ctx = described_class.build(controller, { a: 1 })
    expect(ctx.respond_to?(:a)).to be true
    expect(ctx.respond_to?(:b)).to be false
  end
end
