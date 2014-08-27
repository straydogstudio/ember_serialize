class CommentSerializer < ActiveModel::Serializer
  attributes :id, :title, :body, :post_id
  has_one :author, class_name: 'User'
end
