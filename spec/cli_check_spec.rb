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
end
