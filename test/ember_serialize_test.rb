require 'test_helper'

class EmberSerializeTest < ActiveSupport::TestCase
  def setup
    setup_default_serializer
    setup_create_serializer
  end

  def setup_default_serializer
    return if @serializer
    Rake::Task.define_task(:environment)
    @rapp ||= Rake::Application.new
    @blank_args = Rake::TaskArguments.new([],[])
    @jdir ||= "test/dummy/app/assets/javascripts/"
    @mdir ||= "#{@jdir}models/"
    EmberSerialize::Serializer.javascripts_dir ||= @jdir
    @serializer = EmberSerialize::Serializer.new(@blank_args)
  end

  def setup_create_serializer
    return if @create_serializer
    Rake::Task.define_task(:environment)
    @rapp ||= Rake::Application.new
    @create_args = Rake::TaskArguments.new([],[':create'])
    @jdir ||= "test/dummy/app/assets/javascripts/"
    @mdir ||= "#{@jdir}models/"
    EmberSerialize::Serializer.javascripts_dir ||= @jdir
    @create_serializer = EmberSerialize::Serializer.new(@create_args)
  end

  def prep_model(source, model)
    FileUtils.cp "#{@mdir}/tests/#{source}.js.coffee",
      "#{@mdir}#{model}.js.coffee"
  end

  def read_model(model, pattern = nil)
    file = "#{@mdir}#{model}.js.coffee"
    return nil unless File.exists? file
    lines = File.readlines file
    if pattern
      lines.grep(pattern).first
    else
      lines
    end
  end

  def clear_models
    FileUtils.rm Dir["#{@mdir}*.js.coffee"]
    FileUtils.rm Dir["#{@mdir}*.js.em"]
  end

  def revert_models
    clear_models
    Dir["#{@mdir}default/*"].each do |f|
      FileUtils.cp f, @mdir
    end
  end

  test "existence" do
    assert_kind_of Class, EmberSerialize::Serializer
  end

  test "initialize" do
    assert_equal "ember_serialize:start", @serializer.est
    assert_equal "ember_serialize:end", @serializer.een
    assert_equal "ember_serialize:ignore", @serializer.eig
    assert_equal "ember_serialize:as_is", @serializer.eai
    assert_equal "ember_serialize:async", @serializer.eas
    assert_equal ".js.coffee", @serializer.extension
    assert_equal "test/dummy/app/assets/javascripts/", @serializer.javascripts_dir
    assert_equal "test/dummy/app/assets/javascripts/models/", @serializer.models_dir
    assert File.exists? @serializer.models_dir
  end

  test "camelize name" do
    assert_equal "withUnderscore", @serializer.camel("with_underscore")
    assert_equal "alreadyCamel", @serializer.camel("alreadyCamel")
    assert_equal "className", @serializer.camel("ClassName")
  end

  test "app name" do
    assert_equal "EmberSerialize", @serializer.ember_app_name
  end

  test "ember_model" do
    assert_equal <<WITHEM.split(/\n/), @serializer.ember_model("App", Post, "  ", ".js.em")
# for more details see: http://emberjs.com/guides/models/defining-models/

class App.Post extends DS.Model
  # ember_serialize:start
  # ember_serialize:end
WITHEM
    assert_equal <<WITHOUTEM.split(/\n/), @serializer.ember_model("App", Post, "  ", ".js.coffee")
# for more details see: http://emberjs.com/guides/models/defining-models/

App.Post = DS.Model.extend
  # ember_serialize:start
  # ember_serialize:end
WITHOUTEM
  end

  test "ember_reflect attribute" do
    assert_equal ["id", "  id: DS.attr('integer')"], @serializer.ember_reflect(Post, :id, :attribute, false, {}, '  ', :integer), 'attribute integer'
    assert_equal ["title", "  title: DS.attr('string')"], @serializer.ember_reflect(Post, :title, :attribute, false, {}, '  ', :string), 'attribute string'
  end

  test "ember_reflect belongs_to" do
    assert_equal ["post", "  post: DS.belongsTo('post')"], @serializer.ember_reflect(Comment, :post, :belongs_to, false, {}, '  '), 'belongs_to direct'
    assert_equal ["post", "  post: DS.belongsTo('post', {async: true})"], @serializer.ember_reflect(Comment, :post, :belongs_to, true, {}, '  '), 'belongs_to async'
    assert_equal ["post", "  post: DS.belongsTo('post')"], @serializer.ember_reflect(Comment, :post_id, :belongs_to, false, {}, '  '), 'belongs_to direct with id'
    assert_equal ["postId", "  postId: DS.attr('integer')"], @serializer.ember_reflect(Comment, :post_id, :as_is, false, {}, '  ', 'integer'), 'belongs_to as_is'
    assert_equal ["authorDude", "  authorDude: DS.belongsTo('user')"], @serializer.ember_reflect(Post, :author_dude, :belongs_to, false, {}, '  '), 'belongs_to associated'
    assert_equal ["post", "  post: DS.belongsTo('post', {inverse: 'lemoo'})"], @serializer.ember_reflect(Comment, :post, :belongs_to, false, {'post' => "  post: DS.belongsTo('post', {inverse: 'lemoo'})"}, '  '), 'belongs_to existing'
  end

  test "ember_reflect has_many" do
    assert_equal ["posts", "  posts: DS.hasMany('posts')"], @serializer.ember_reflect(User, :posts, :has_many, false, {}, '  '), 'has_many'
    assert_equal ["posts", "  posts: DS.hasMany('posts', {async: true})"], @serializer.ember_reflect(User, :posts, :has_many, true, {}, '  '), 'has_many async true'
    assert_equal ["posts", "  posts: DS.hasMany('posts', {inverse: 'lemoo'})"], @serializer.ember_reflect(User, :posts, :has_many, false, {'posts' => "  posts: DS.hasMany('posts', {inverse: 'lemoo'})"}, '  '), 'has_many existing'
  end

  test "parses model" do
    revert_models
    match = [["# for more details see: http://emberjs.com/guides/models/defining-models/", "", "EmberSerialize.Post = DS.Model.extend", "  # ember_serialize:start", "  id: DS.attr('integer'),", "  title: DS.attr('string'),", "  body: DS.attr('text'),", "  comments: DS.hasMany('comments')", "  # ember_serialize:end"], 3, 8, {"id"=>"  id: DS.attr('integer')", "title"=>"  title: DS.attr('string')", "body"=>"  body: DS.attr('text')", "comments"=>"  comments: DS.hasMany('comments')"}, [], [], true, "  "]
    result = @serializer.ember_model_parse "#{@mdir}post.js.coffee", Post
    assert_equal match, result, 'ember_model_parse'
  end

  test "builds model" do
    ams = ActiveModel::Serializer.descendants.sort_by(&:name)[1]
    args = [["# for more details see: http://emberjs.com/guides/models/defining-models/", "", "EmberSerialize.Post = DS.Model.extend", "  # ember_serialize:start", "  # ember_serialize:async false", "  id: DS.attr('integer'),", "  title: DS.attr('string'),", "  body: DS.attr('text'),", "  authorDude: DS.belongsTo('user'),", "  comments: DS.hasMany('comments')", "  # ember_serialize:end"], 3, 10, {"id"=>"  id: DS.attr('integer')", "title"=>"  title: DS.attr('string')", "body"=>"  body: DS.attr('text')", "authorDude"=>"  authorDude: DS.belongsTo('user')", "comments"=>"  comments: DS.hasMany('comments')"}, [], [], false, "  "]
    match = "# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Post = DS.Model.extend
  # ember_serialize:start
  # ember_serialize:async false
  id: DS.attr('integer'),
  title: DS.attr('string'),
  body: DS.attr('text'),
  authorDude: DS.belongsTo('user'),
  comments: DS.hasMany('comments')
  # ember_serialize:end"
    result = @serializer.ember_model_build @serializer.schema(ams),
      Post, args
    assert_equal match, result, 'ember_model_build'
  end

  test "serializes match parameter" do
    clear_models
    @create_serializer.serialize "Post"
    assert_equal 1, Dir["#{@mdir}*.js.coffee"].length, "uses match parameter"
  end

  test "serialize finds existing" do
    revert_models
    prep_model 'find_existing', 'post'
    @serializer.serialize
    assert_match /find_existing/, read_model('post', /authorDude:/), 'finds existing'
  end

  test "serialize ignores outside" do
    revert_models
    prep_model 'ignore_outside', 'post'
    @serializer.serialize
    assert_match /ignore_outside/, read_model('post', /authorDude:/), 'ignores outside'
  end

  test "serialize ignore setting" do
    revert_models
    prep_model 'ignore', 'post'
    @serializer.serialize
    assert read_model('post', /body:/).nil?, 'ignore setting'
  end

  test "serialize as_is setting" do
    revert_models
    prep_model 'as_is', 'comment'
    @serializer.serialize
    assert_equal "  postId: DS.attr('integer'),\n", read_model('comment', /postId:/), 'as_is setting'
  end

  test "serialize finds associations" do
    revert_models
    File.unlink "#{@mdir}post.js.coffee"
    @create_serializer.serialize
    assert_equal "  authorDude: DS.belongsTo('user', {async: true}),\n", read_model('post', /authorDude:/), 'finds associations'
  end

  test "skips or creates models" do
    revert_models
    File.unlink "#{@mdir}post.js.coffee"
    @serializer.serialize
    assert !File.exists?("#{@mdir}post.js.coffee"), 'skips model'
    clear_models
    @create_serializer.serialize
    assert_equal 3, Dir["#{@mdir}*js.coffee"].length, 'creates models'
  end

  test "accepts async argument" do
    revert_models
    async_args = Rake::TaskArguments.new([],['async:true'])
    async_serializer = EmberSerialize::Serializer.new(async_args)
    prep_model 'async', 'post'
    async_serializer.serialize
    lines = read_model('post')
    assert lines.grep(/#{async_serializer.eas}/).first.nil?, 'async:true leaves no setting'
    assert_match /async: true/, lines.grep(/authorDude:/).first, 'accepts async arg'
  end

  test "parses async argument" do
    revert_models
    prep_model 'async_parse', 'post'
    @serializer.serialize
    lines = read_model('post')
    assert !lines.grep(/#{@serializer.eas} false/).first.nil?, 'ember_serializer:async false stays'
    assert_no_match /async: true/, lines.grep(/authorDude:/).first, 'parses async arg'
  end

  test "accepts engine argument" do
    revert_models
    # engine serializer
    engine_args = Rake::TaskArguments.new([],[':create','engine:em'])
    engine_serializer = EmberSerialize::Serializer.new(engine_args)
    # prep dir
    clear_models
    # serialize using engine parameter
    engine_serializer.serialize
    # there should be 3 .js.em files
    assert_equal 3, Dir["#{@mdir}*js.em"].length, 'creates em models'
    # remove one file
    FileUtils.rm "#{@mdir}post.js.em"
    default_serializer = EmberSerialize::Serializer.new(@create_args)
    default_serializer.serialize
    # serialize should detect em and restore missing post
    assert_equal 3, Dir["#{@mdir}*js.em"].length, 'detects em engine type'

    # coffee engine serializer
    engine_args = Rake::TaskArguments.new([],[':create','engine:coffee'])
    engine_serializer = EmberSerialize::Serializer.new(engine_args)
    # prep dir
    clear_models
    # serialize using engine parameter
    engine_serializer.serialize
    # there should be 3 .js.coffee files
    assert_equal 3, Dir["#{@mdir}*js.coffee"].length, 'creates coffee models'
    # remove one file
    FileUtils.rm "#{@mdir}post.js.coffee"
    default_serializer = EmberSerialize::Serializer.new(@create_args)
    default_serializer.serialize
    # serialize should detect coffee and restore missing post
    assert_equal 3, Dir["#{@mdir}*js.coffee"].length, 'detects coffee engine type'
  end

  test "makes model directory" do
    FileUtils.mv @mdir, "#{@jdir}models_aside"
    some_serializer = EmberSerialize::Serializer.new(@blank_args)
    assert File.exists?(@mdir), "makes model directory"
    FileUtils.rm_r @mdir
    FileUtils.mv "#{@jdir}models_aside", @mdir
  end
end
