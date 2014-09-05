class CommentSerializer < ApplicationSerializer
  attributes :id, :title, :body, :post_id
  has_one :author, class_name: 'User'
end
