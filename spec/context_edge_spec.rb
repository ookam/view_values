# frozen_string_literal: true

RSpec.describe ViewValues::Context do
  let(:controller) { Object.new }

  it "prefers explicit data over helper method with same name" do
    expect {
      described_class.build(controller, { current_user: :explicit }, helpers: %i[current_user])
    }.to raise_error(ArgumentError, /conflicting key 'current_user'/)
  end

  it "responds to defined keys and not to others" do
    ctx = described_class.build(controller, { a: 1 })
    expect(ctx.respond_to?(:a)).to be true
    expect(ctx.respond_to?(:b)).to be false
  end

  it "raises at build time when helper does not exist" do
    expect {
      described_class.build(controller, {}, helpers: %i[no_such_helper])
    }.to raise_error(NoMethodError, /undefined helper 'no_such_helper'/)
  end

  it "raises when explicit data provides the same key as helpers" do
    expect {
      described_class.build(controller, { no_such_helper: :ok }, helpers: %i[no_such_helper])
    }.to raise_error(ArgumentError, /conflicting key 'no_such_helper'/)
  end
end
