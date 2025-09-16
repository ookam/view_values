# frozen_string_literal: true

RSpec.describe 'Feature coverage' do
  describe ViewValues::Context do
    let(:controller) do
      Class.new do
        def current_user = Struct.new(:name).new('Carol')
        def is_login? = true
      end.new
    end

    it 'includes configured instance var name in error message' do
      orig = ViewValues.config.instance_var_name
      begin
        ViewValues.config.instance_var_name = :vv
        ctx = ViewValues::Context.build(controller, {})
        expect { ctx.unknown }.to raise_error(NoMethodError, /@vv/)
      ensure
        ViewValues.config.instance_var_name = orig
      end
    end

    it 'adds helpers to keys and respond_to?' do
      ctx = ViewValues::Context.build(controller, {}, helpers: %i[current_user is_login?])
      expect(ctx.keys).to include(:current_user, :is_login?)
      expect(ctx.respond_to?(:current_user)).to be true
      expect(ctx.respond_to?(:is_login?)).to be true
    end

    it 'is frozen after initialization' do
      ctx = ViewValues::Context.build(controller, {})
      expect(ctx).to be_frozen
    end

    it 'does not support hash access (dot only)' do
      ctx = ViewValues::Context.build(controller, { user: 1 })
      expect { ctx[:user] }.to raise_error(NoMethodError)
    end

    it 'evaluates helpers lazily at call time' do
      c = Class.new do
        attr_accessor :flag
        def current_user = flag ? Struct.new(:name).new('After') : Struct.new(:name).new('Before')
      end.new
      c.flag = false
      ctx = ViewValues::Context.build(c, {}, helpers: %i[current_user])
      expect(ctx.current_user.name).to eq 'Before'
      c.flag = true
      expect(ctx.current_user.name).to eq 'After'
    end
  end

  describe ViewValues::Provider do
    let(:controller_class) do
      Class.new do
        include ViewValues::Provider
        def self.helper_method(*) ; end
      end
    end

    it 'returns nil before build_view_values is called' do
      c = controller_class.new
      expect(c.view_values).to be_nil
    end
  end
end
