require 'rails'
module EmberSerialize
  class Railtie < Rails::Railtie
    railtie_name :ember_serialize

    rake_tasks do
      load "tasks/ember_serialize_tasks.rake"
    end
  end
end