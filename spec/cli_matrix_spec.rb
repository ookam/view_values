# frozen_string_literal: true

RSpec.describe 'view_values CLI matrix' do
  let(:exe) { File.expand_path('../exe/view_values', __dir__) }
  let(:root) { File.expand_path('..', __dir__) }

  def run_check(include_glob: nil, instance_var: nil, only_action: nil)
    args = [Gem.ruby, exe, 'check', '--root', root]
    args += ['--include', include_glob] if include_glob
    args += ['--instance-var', instance_var] if instance_var
    args += ['--only-action', only_action] if only_action
    out = IO.popen(args, err: [:child, :out]) { |io| io.read }
    [out, $?.exitstatus]
  end

  # Data only
  it 'OK when declared=0 used=0' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'a0')
    expect(status).to eq(0)
    expect(out).to include('view_values check: OK')
  end

  it 'NG unused when declared=1 used=0' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'a1')
    expect(status).to eq(1)
    expect(out).to include('NG: CliMatrix::MatrixController#a1')
    expect(out).to include('unused (declared but not used): a')
  end

  it 'OK when declared=1 used=1' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'a2')
    expect(status).to eq(0)
    expect(out).to include('view_values check: OK')
  end

  it 'NG unused when declared=2 used=1' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'a3')
    expect(status).to eq(1)
    expect(out).to include('NG: CliMatrix::MatrixController#a3')
    expect(out).to include('unused (declared but not used): b')
  end

  it 'NG missing when declared=0 used=1' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'a4')
    expect(status).to eq(1)
    expect(out).to include('NG: CliMatrix::MatrixController#a4')
    expect(out).to include('missing (used but not declared): a')
  end

  it 'OK when nested usage counts root (post.title -> post)' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'a5')
    expect(status).to eq(0)
    expect(out).to include('view_values check: OK')
  end

  # Helpers only
  it 'NG unused helper when declared=1 used=0' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'h1')
    expect(status).to eq(1)
    expect(out).to include('NG: CliMatrix::MatrixController#h1')
    expect(out).to include('unused (declared but not used): is_login?')
  end

  it 'NG unused helper when declared=2 used=1' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'h2')
    expect(status).to eq(1)
    expect(out).to include('NG: CliMatrix::MatrixController#h2')
    expect(out).to include('unused (declared but not used): h2')
  end

  it 'OK when helpers declared=2 used=2' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'h3')
    expect(status).to eq(0)
    expect(out).to include('view_values check: OK')
  end

  it 'NG missing when helper used but not declared' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'h4')
    expect(status).to eq(1)
    expect(out).to include('NG: CliMatrix::MatrixController#h4')
    expect(out).to include('missing (used but not declared): missing_helper')
  end

  # Mixed
  it 'OK when value+helper both used' do
    out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'm1')
    expect(status).to eq(0)
  end

  it 'NG unused value when only helper used' do
    out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'm2')
    expect(status).to eq(1)
    expect(out).to include('unused (declared but not used): a')
  end

  it 'NG unused both sides when partially used' do
    out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'm3')
    expect(status).to eq(1)
    expect(out).to include('unused (declared but not used): b, h2')
  end

  # Formats & literals
  it 'OK for multiline build_view_values and mixed literals' do
    out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'f1')
    expect(status).to eq(0)
  end

  it 'OK for string data keys {"str"=>...}' do
    out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'f2')
    expect(status).to eq(0)
  end

  it 'OK for helpers literal [:a, "b"]' do
    out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'f3')
    expect(status).to eq(0)
  end

  # Instance var name
  it 'OK for custom instance var name with --instance-var=vv' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', instance_var: 'vv', only_action: 'v1')
    expect(status).to eq(0)
  end

  # Comment allow-list
  it 'OK when usage is declared in comment allow-list' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'c1')
    expect(status).to eq(0)
  end

  # Ignored patterns
  it 'NG unused when accessed via try (not dot)' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'x1')
    expect(status).to eq(1)
    expect(out).to include('unused (declared but not used): a')
  end

  # No view file
  it 'NG unused when declared but no view present' do
  out, status = run_check(include_glob: 'cli_matrix/matrix_controller.rb', only_action: 'n1')
    expect(status).to eq(1)
    expect(out).to include('NG: CliMatrix::MatrixController#n1')
    expect(out).to include('unused (declared but not used): a')
  end
end
