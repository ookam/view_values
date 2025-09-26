# frozen_string_literal: true

RSpec.describe "view_values skip directive" do
  let(:exe) { File.expand_path("../exe/view_values", __dir__) }
  let(:root) { File.expand_path("..", __dir__) }
  let(:base_cmd) { [Gem.ruby, exe, "check", "--root", root, "--include=skip_controller"] }

  it "ignores controller actions that contain skip:view_values" do
    out = IO.popen(base_cmd + ["--only-action=flagged"], err: [:child, :out]) { |io| io.read }
    status = $?.exitstatus
    expect(status).to eq(0)
    expect(out).to include("view_values check: *SKIP*")
  end

  it "ignores views that contain skip:view_values" do
    out = IO.popen(base_cmd + ["--only-action=view_only"], err: [:child, :out]) { |io| io.read }
    status = $?.exitstatus
    expect(status).to eq(0)
    expect(out).to include("view_values check: *SKIP*")
  end
end
