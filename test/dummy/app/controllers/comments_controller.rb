class CommentsController < ApplicationController
  respond_to :json

  def index
    respond_with Comment.first(100)
  end
end
