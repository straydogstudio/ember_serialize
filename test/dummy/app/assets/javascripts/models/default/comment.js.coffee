# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.Comment = DS.Model.extend
  # ember_serialize:start
  id: DS.attr('integer'),
  title: DS.attr('string'),
  body: DS.attr('text'),
  author: DS.belongsTo('user'),
  post: DS.belongsTo('post')
  # ember_serialize:end
