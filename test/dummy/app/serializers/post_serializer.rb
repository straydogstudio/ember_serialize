class PostSerializer < ApplicationSerializer
  attributes :id, :title, :body, :created_at
  has_one :author_dude, class_name: 'User'
  has_many :comments
end
