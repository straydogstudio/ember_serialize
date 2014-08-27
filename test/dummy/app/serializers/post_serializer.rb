class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :body
  has_one :author_dude, class_name: 'User'
  has_many :comments
end
