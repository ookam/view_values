# frozen_string_literal: true

class PostsController
  def show
    build_view_values({ user: :u }, helpers: %i[is_login?])
  end

  def edit
    build_view_values({ user: :u })
  end

  def new
    build_view_values({ user: :u })
  end
end
