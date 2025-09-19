# frozen_string_literal: true
module CliMatrix
  class MatrixController < ActionController::Base
    include ViewValues::Provider

    # Data only
    def a0; build_view_values({}); end
    def a1; build_view_values({ a: 1 }); end
    def a2; build_view_values({ a: 1 }); end
    def a3; build_view_values({ a: 1, b: 2 }); end
    def a4; build_view_values({}); end
    def a5; build_view_values({ post: OpenStruct.new(title: 't') }); end

    # Helpers only
    def h1; build_view_values({}, helpers: %i[is_login?]); end
    def h2; build_view_values({}, helpers: %i[h1 h2]); end
    def h3; build_view_values({}, helpers: %i[h1 h2]); end
    def h4; build_view_values({}); end

    # Mixed
    def m1; build_view_values({ a: 1 }, helpers: %i[h1]); end
    def m2; build_view_values({ a: 1 }, helpers: %i[h1]); end
    def m3; build_view_values({ a: 1, b: 2 }, helpers: %i[h1 h2]); end

    # Formats & literals
    def f1
      build_view_values(
        {
          'str' => 1,
          sym: 2
        },
        helpers: %i[h1 h2]
      )
    end
    def f2; build_view_values({ 'str' => 1 }); end
    def f3; build_view_values({}, helpers: [:h1, 'h2']); end

    # Instance var name
    def v1
      build_view_values({ a: 1 })
      @vv = @view_values
    end

    # Comment allow-list
    def c1; build_view_values({ c: 1 }); end

    # Ignored patterns
    def x1; build_view_values({ a: 1 }); end

    # No view file
    def n1; build_view_values({ a: 1 }); end

    private
    def is_login?; true; end
    def h1; :ok; end
    def h2; :ok; end
  end
end
