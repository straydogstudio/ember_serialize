class PostsController < ApplicationController
  respond_to :json

  def index
    respond_with Post.first(100)
  end
end
