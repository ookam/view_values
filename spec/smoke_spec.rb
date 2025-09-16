# frozen_string_literal: true

RSpec.describe ViewValues do
  it "has a version number" do
    expect(ViewValues::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  it "defines a custom Error class" do
    expect(ViewValues::Error).to be < StandardError
  end
end
