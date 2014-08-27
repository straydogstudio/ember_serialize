namespace :db do
  namespace :schema do
    desc 'Regenerate Ember models from ActiveModel::Serializers'
    task :ember => :environment do |task, args|
      puts "WE ARE BEIGN INVOKED!!!!"
      EmberSerialize::Serializer.new(args).serialize
    end
  end
end
