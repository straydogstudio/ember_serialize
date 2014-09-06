module EmberSerialize
  require 'ember_serialize/railtie' if defined?(Rails)

  class Serializer
    class << self
      attr_accessor :javascripts_dir, :models_dir
    end

    attr_accessor :args, :est, :een, :eig, :eai, :eas, :missing, :javascripts_dir, :models_dir, :extension

    def initialize(args)
      @args = args
      # args
      @missing = args.extras.include?(':create') ? :create : :skip
      @force_async = args.extras.grep(/^async\:/) {|e| e =~ /true/}.first
      # variables
      @est = "ember_serialize:start"
      @een = "ember_serialize:end"
      @eig = "ember_serialize:ignore"
      @eai = "ember_serialize:as_is"
      @eas = "ember_serialize:async"
      @javascripts_dir = self.class.javascripts_dir || "app/assets/javascripts/"
      @models_dir = self.class.models_dir || @javascripts_dir+"models/"
      unless File.exists? @models_dir
        require 'fileutils'
        FileUtils.mkdir_p @models_dir
      end
      # engine / extension
      engine = args.extras.grep(/^engine\:/) {|e| e.gsub(/^.*:/,'').to_sym}.first
      if engine == :coffee
        @extension = ".js.coffee"
      elsif engine == :em
        @extension = ".js.em"
      else
        @extension = detect_extension
      end
    end

    def serialize(match = nil)
      # populate Rails descendants
      Rails.application.eager_load!

      # loop through serializers
      ActiveModel::Serializer.descendants.sort_by(&:name).each do |serializer|
        if match
          next unless serializer.name =~ /^#{match}/
        end
        model = model_class serializer
        next unless model
        schema = schema serializer
        ember_model_file = @models_dir + model.table_name.singularize + @extension
        new_content = ember_model_build(schema, model, ember_model_parse(ember_model_file, model))
        if new_content
          File.write ember_model_file, new_content
        end
      end
    end

    def detect_extension
      Dir[@models_dir+"*js.em"].blank? ? ".js.coffee" : ".js.em"
    end

    def camel(name)
      name.to_s.underscore.camelize(:lower)
    end

    def ember_app_name(javascripts_dir = @javascripts_dir)
      @app_name ||= begin
        appname = Dir[javascripts_dir+"*"].select do |f|
          File.file?(f)
        end.map do |f|
          open(f) do |f|
            f.each_line.detect do |l|
              /Ember.Application.create/.match(l)
            end
          end
        end.compact.first.strip.gsub /.*window\.(\w+) =.*$/, '\1'
      end
    end

    def ember_model(app_name, model, indent, extension)
      klass = if extension == '.js.em'
        "class #{app_name}.#{model.name} extends DS.Model"
      else
        "#{app_name}.#{model.name} = DS.Model.extend"
      end
      lines = <<MODEL
# for more details see: http://emberjs.com/guides/models/defining-models/

#{klass}
#{indent}# ember_serialize:start
#{indent}# ember_serialize:end
MODEL
      lines.split /\n/
    end

    def ember_reflect(model, name, rel, async, existing, indent, type = 'string')
      foreign_name = name.to_s.gsub(/_id$/, '').to_sym
      _async = async ? ", {async: true}" : ''
      assoc = model.reflect_on_all_associations.select do |a|
        a.name == foreign_name && a.macro == rel.to_sym
      end.first
      camel_name = camel(name)
      line = if assoc
        if rel == :belongs_to || rel == :has_one
          camel_name = camel(foreign_name)
          if existing[camel_name].to_s =~ /belongsTo/
            existing[camel_name]
          else
            assoc_name = assoc.table_name.singularize
            "#{indent}#{camel_name}: DS.belongsTo('#{assoc_name}'#{_async})"
          end
        else
          if existing[camel_name].to_s =~ /hasMany/
            existing[camel_name]
          else
            "#{indent}#{camel_name}: DS.hasMany('#{camel_name}'#{_async})"
          end
        end
      else
        existing[camel_name] || "#{indent}#{camel_name}: DS.attr('#{type || 'string'}')"
      end
      [camel_name, line]
    end

    def ember_model_parse(ember_model_file, model)
      if !File.exists? ember_model_file
        if @missing == :create
          # create default file
          lines = ember_model ember_app_name, model, "  ", @extension
        else
          return nil
        end
      else
        lines = File.readlines(ember_model_file).map(&:rstrip)
      end

      # find start/end markers
      line_start = lines.index {|l| l =~ /#{@est}/}
      line_end = lines.index {|l| l =~ /#{@een}/}

      if line_start && line_end
        # find settings for ignore, as_is, and async
        ignore = setting_ignore lines
        as_is = setting_as_is lines
        if @force_async.nil?
          async = setting_async lines
        else
          async = @force_async
        end

        # match the indent of the start line
        indent = lines[line_start][/\A */]

        # catalog existing lines
        existing = {}
        outside = []
        lines.each_with_index do |line, i|
          next if line =~ /^\s*#/ # reject comments
          next unless line =~ /:\s*DS\./ #include DS lines
          # reformat the line
          name, ds = line.strip.gsub(/,$/,'').split(/:\s*/,2)
          name = camel name
          # save lines inside range as existing
          if i > line_start && i < line_end
            existing[name] = "#{indent}#{name}: #{ds}"
          else # ignore ones outside the range
            ignore << name
          end
        end
        [lines, line_start, line_end, existing, ignore.uniq, as_is, async, indent]
      else
        nil
      end
    end

    def ember_model_build(schema, model, args)
      return nil unless args && args.length == 8
      lines, line_start, line_end, existing, ignore, as_is, async, indent = args
      new_lines = []

      # build attributes
      schema[:attributes].each do |name,type|
        camel_name, line = if name =~ /_id$/ &&
            type == :integer &&
            !as_is.include?(name) &&
            !as_is.include?(camel(name))
          ember_reflect(model, name, :belongs_to, async, existing, indent, type)
        else
          ember_reflect(model, name, :attribute, async, existing, indent, type)
        end
        next if camel_name == 'id'
        unless ignore.include? camel_name
          new_lines << line
          ignore << camel_name
        end
      end

      # build associations
      schema[:associations].each do |key, assoc|
        next if assoc.nil?
        rel, table = assoc.flatten
        camel_name, line = ember_reflect(model, table, rel, async, existing, indent)
        unless ignore.include? camel_name
          new_lines << line
        end
      end

      # build final content
      content = [ lines[0..line_start].join("\n") ]
      # write original ignore setting
      ignore_setting = setting_ignore(lines)
      unless ignore_setting.blank?
        content << "#{indent}# #{@eig} #{ignore_setting.join(", ")}"
      end
      unless as_is.blank?
        content << "#{indent}# #{@eai} #{as_is.join(", ")}"
      end
      if async == false
        content << "#{indent}# #{@eas} false"
      end
      content << new_lines.join(",\n")
      content << lines[line_end..-1].join("\n")

      content.join("\n")
    end

    def model_class(serializer)
      if serializer.respond_to? :model_class
        begin
          return serializer.model_class
        rescue NameError
          return nil
        end
      end
      @model_classes ||= Hash.new do |h,k|
        h[k] = k.name.gsub(/Serializer$/,'').constantize
      end
      @model_classes[serializer]
    end

    def schema(serializer)
      if serializer.respond_to? :schema
        serializer.schema
      else 
        {}
      end
    end

    def setting_ignore(lines)
      lines.grep(/#{@eig}/) do |l|
        l.gsub(/.*#{@eig} (.*)\s*$/, '\1').split(/[\s,]+/)
      end.flatten.uniq.map {|t| camel(t)}
    end

    def setting_as_is(lines)
      lines.grep(/#{@eai}/) do |l|
        l.gsub(/.*#{@eai} (.*)\s*$/, '\1').split(/[\s,]+/)
      end.flatten.uniq.map {|t| camel(t)}
    end

    def setting_async(lines)
      async = lines.grep(/#{@eas}/) do |l|
        l.gsub(/.*#{@eai} (.*)\s*$/, '\1') == 'true'
      end.flatten.last
      async.nil? ? true : async
    end
  end
end
