namespace :db do
  namespace :schema do
    desc 'Regenerate Ember models from ActiveModel::Serializers'
    task :ember => :environment do |task, args|
      EmberSerialize::Serializer.new(args).serialize
    end
  end
end
