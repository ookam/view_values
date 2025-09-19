# frozen_string_literal: true

RSpec.describe 'view_values CLI check' do
  let(:exe) { File.expand_path('../exe/view_values', __dir__) }
  let(:root) { File.expand_path('..', __dir__) }

  it 'returns non-zero when undeclared keys are used' do
    out = IO.popen([Gem.ruby, exe, 'check', '--root', root], err: [:child, :out]) { |io| io.read }
    status = $?.exitstatus
    expect(status).to eq(1)
    expect(out).to include('NG: PostsController#edit')
    expect(out).to include('unknown_key')
  end

  it 'detects helpers from multiline build_view_values and does not flag as missing' do
    out = IO.popen([Gem.ruby, exe, 'check', '--root', root], err: [:child, :out]) { |io| io.read }
    # Should not report the Member::HomesController#show as missing is_member_login?
    expect(out).not_to include('NG: Member::HomesController#show')
    expect(out).not_to include('is_member_login?')
  end
end
