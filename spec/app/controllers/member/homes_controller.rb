# frozen_string_literal: true

module Member
  class HomesController < ActionController::Base
    include ViewValues::Provider

    def show
      build_view_values(
        {
          test: :ok
        },
        helpers: %i[is_member_login?]
      )
    end

    private

    def is_member_login?
      true
    end
  end
end
