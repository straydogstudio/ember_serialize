class UsersController < ApplicationController
  respond_to :json

  def index
    respond_with User.first(100)
  end
end
