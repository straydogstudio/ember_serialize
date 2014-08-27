class Post < ActiveRecord::Base
  belongs_to :author_dude, class_name: 'User'
  has_many :comments
end
