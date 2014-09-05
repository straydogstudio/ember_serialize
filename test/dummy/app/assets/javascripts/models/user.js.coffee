# for more details see: http://emberjs.com/guides/models/defining-models/

EmberSerialize.User = DS.Model.extend
  # ember_serialize:start
  name: DS.attr('string')
  # ember_serialize:end