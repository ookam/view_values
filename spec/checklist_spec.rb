# frozen_string_literal: true

RSpec.describe 'README checklist' do
  describe '1) Build/basic access' do
    let(:controller_class) do
      Class.new do
        include ViewValues::Provider
        def self.helper_method(*) ; end
      end
    end

    it 'build_view_values generates @view_values (non-nil)' do
      c = controller_class.new
      expect(c.view_values).to be_nil
      c.build_view_values({})
      expect(c.view_values).not_to be_nil
    end

    it 'symbol and string keys are both accessible via dot' do
      c = controller_class.new
      c.build_view_values({ 'post' => 1, user: 2 })
      vv = c.view_values
      expect(vv.post).to eq 1
      expect(vv.user).to eq 2
    end

    it 'raises NoMethodError with key name for undefined key' do
      c = controller_class.new
      c.build_view_values({})
      expect { c.view_values.unknown_key }.to raise_error(NoMethodError, /unknown_key/)
    end

    it 'respond_to? returns true for root keys' do
      c = controller_class.new
      c.build_view_values({ a: 1 })
      expect(c.view_values.respond_to?(:a)).to be true
    end
  end

  describe '2) Helpers injection' do
    let(:controller_class) do
      Class.new do
        include ViewValues::Provider
        def self.helper_method(*) ; end

        attr_accessor :flag
        def current_user = flag ? :after : :before
      end
    end

    it 'exposes helper via dot and evaluates lazily' do
      c = controller_class.new
      c.flag = false
      c.build_view_values({}, helpers: %i[current_user])
      expect(c.view_values.current_user).to eq :before
      c.flag = true
      expect(c.view_values.current_user).to eq :after
    end

    it 'raises when data and helpers have the same key' do
      c = controller_class.new
      expect {
        c.build_view_values({ current_user: :x }, helpers: %i[current_user])
      }.to raise_error(ArgumentError, /conflicting key 'current_user'/)
    end

    it 'non-existent helper raises at build time' do
      c = controller_class.new
      expect {
        c.build_view_values({}, helpers: %i[nonexistent])
      }.to raise_error(NoMethodError, /undefined helper 'nonexistent'/)
    end
  end

  describe '3) Dot-only behavior' do
    it '[] raises NoMethodError; dot works' do
      c = Class.new { include ViewValues::Provider; def self.helper_method(*) ; end }.new
      c.build_view_values({ user: :u })
      expect(c.view_values.user).to eq :u
      expect { c.view_values[:user] }.to raise_error(NoMethodError)
    end
  end

  describe '4) Immutability and overwrite' do
    it 'no public setters for root and last build overwrites previous' do
      c = Class.new { include ViewValues::Provider; def self.helper_method(*) ; end }.new
      c.build_view_values({ a: 1 })
      expect { c.view_values.a = 2 }.to raise_error(NoMethodError)
      c.build_view_values({ a: 3 })
      expect(c.view_values.a).to eq 3
    end
  end

  describe '7) instance_var_name setting' do
    it 'supports custom instance var and does not set default one' do
      orig = ViewValues.config.instance_var_name
      begin
        ViewValues.config.instance_var_name = :vv
        c = Class.new { include ViewValues::Provider; def self.helper_method(*) ; end }.new
        c.build_view_values({ a: 1 })
        expect(c.instance_variable_defined?(:@vv)).to be true
        expect(c.instance_variable_defined?(:@view_values)).to be false
      ensure
        ViewValues.config.instance_var_name = orig
      end
    end
  end

  describe '8) Priority & duplicates' do
    it 'duplicate helper names do not change the result' do
      c = Class.new do
        include ViewValues::Provider
        def self.helper_method(*) ; end
        def current_user = :u
      end.new
      c.build_view_values({}, helpers: %i[current_user current_user])
      expect(c.view_values.current_user).to eq :u
    end
  end

  describe '9) Key visibility' do
    it 'keys returns all root keys; empty? reflects no data/helpers' do
      c = Class.new do
        include ViewValues::Provider
        def self.helper_method(*) ; end
        def is_login? = true
      end.new
      c.build_view_values({ post: 1 }, helpers: %i[is_login?])
      expect(c.view_values.keys).to include(:post, :is_login?)
      expect(c.view_values.empty?).to be false
      c2 = Class.new { include ViewValues::Provider; def self.helper_method(*) ; end }.new
      c2.build_view_values({})
      expect(c2.view_values.empty?).to be true
    end
  end
end
