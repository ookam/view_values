# frozen_string_literal: true

class SkipController
  def flagged
    # skip:view_values
    build_view_values({ declared: :ok })
  end

  def view_only
    build_view_values({ declared: :ok })
  end
end
