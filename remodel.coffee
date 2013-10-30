

if typeof window isnt 'undefined'
  namespace = window.remodel = {}
else
  namespace = module.exports

# Model Pre-loading
if typeof _remodel_warmup isnt 'undefined'
  namespace.warmup = _remodel_warmup
else
  namespace.warmup = {}


# Remember recently used menu items.
namespace.menu_options_sync = (items)->

  @menu_options = [{value: '', text: '...'}]

  for item in items
    @menu_options.push
      value: item.get_id()
      text: item.describe()

  that = items[0].constructor
  
  try
    recent = JSON.parse localStorage['recent_'+that.slug]
  catch e
    recent = {}
  
  # Recent items should be preferred.
  @menu_options = @menu_options.sort (a, b)->
    score = 0
    if a.text > b.text
      score += 1
    else if a.text < b.text
      score -= 1

    recent ?= {}

    recent[a.text] ?= 0
    recent[b.text] ?= 0
    
    score += recent[a.text] - recent[b.text]
    score
  
  localStorage['recent_'+that.slug] = JSON.stringify recent

  @menu_options

namespace.load = (models, cb)->

  # Pre-fetch to avoid callback hell later. TODO - this should be framework code.
  i = 0
  async.map Object.keys(models), (key, done)->
      m = models[key]
      if m.load # Duck typing check this is a model
        m.slug = m.name.toLowerCase()
        m.load ->
          i += 1
          done()
      else # Non-models
        done()
    , ->
      cb()


resolve_model = (model_path)->
  if typeof model_path is 'string'
    model = APP.MODELS[model_path]
  else
    model = model_path
  unless model
    throw 'No model "' + model_path + '" could be resolved.'
  model


class namespace.Model extends retool.Class

  # reverse foreign key lookup
  rlookup: (model, slug)->
    model = resolve_model model
    query = {}
    query[slug] = @get_id()
    model.findWhere query

  # Dereference a foreign key.
  lookup: (slug)->
    model_path = @constructor.fkeys[slug]
    unless model_path
      throw 'Foreign key "' + slug + '" does not exist.'
    model = resolve_model model_path
    model.get @[slug]
  
  # Look up the description associated with a foreign key deref.
  lookup_desc: (slug, def='')->
    item = @lookup(slug)
    if item
      item[item.constructor.desc_attr]
    else
      def

  save: ->
    @constructor.save @

  del: ->
    @constructor.del @get_id()

  @desc_attr: 'name'

  @id_attr: '_id'

  get_id: ->
    @[@constructor.id_attr]
  
  set_id: (id)->
    @[@constructor.id_attr] = id
  
  # String representation of the model.
  describe: ->
    @[@constructor.desc_attr] ? ''

  #constructor: (obj={})->
    #Model.add obj, true # Always hydrate when contructor is used.
  
  # Initialize a new object and put it in the collection.
  @add: (obj, overwrite=false)->
    @hydrate obj
    
    orig = undefined
    id = obj.get_id()

    if id
      orig = @get id
    
    # If the object exists already based on unique id...
    if orig
      if overwrite # If the overwrite flag is set, remove and re-add the object.
        @items = @filter (o)->
          o.get_id() isnt id
        @items.push obj
      else # Otherwise, update it with jQuery extend.
        obj = $.extend orig, obj
    else
      obj.set_id '' + new Date().valueOf() # Default ID is the unix timestamp in milliseconds.
      @items.push obj
    obj

  @save: (obj, overwrite=false)->
    # Whether or not the object is in the collection already
    obj = @add obj, overwrite
    obj

  # Model.del - delete an object m
  @del: (id)->
    if typeof id is 'object' # If we're given a full object, get just the _id
      id = @hydrate(id).get_id()
    @items = @filter (o)->
      o.get_id() isnt id
    id

  @get: (id)->
    query = {}
    query[@id_attr or "_id"] = id
    @findWhere query

  @hydrate: (item)-> # TODO - make this work in old browser. The issue is "new" doesn't update in place.
    item.__proto__ = @prototype
  
  dehydrate: -> # TODO - make this work in old browser. The issue is "new" doesn't update in place.
    delete item.__proto__
  
  @load: (items)->
    @items = items
    for item in @items
      @hydrate item

# Extend with underscore methods.
if typeof _ isnt 'undefined'
  
  underscore_array_methods = [
    'first', 'initial', 'last', 'rest', 'compact', 'flatten', 'without'
    'union', 'intersection', 'difference', 'uniq', 'zip', 'object', 'indexOf'
    'lastIndexOf', 'sortedIndex', 'range'
  ]
  underscore_collection_methods = [
    'each', 'map', 'reduce', 'reduceRight', 'find', 'filter', 'where'
    'findWhere', 'reject', 'every', 'some', 'invoke', 'pluck', 'max'
    'min', 'sortBy', 'groupBy', 'countBy', 'shuffle', 'toArray', 'size'
  ]

  for method in underscore_array_methods.concat underscore_collection_methods
    ((method)->
      namespace.Model[method] = ->
        _[method].apply _, [@items].concat _.toArray arguments
    ) method


ajax_reporter = (result)->
  if result.success is false then console.error result.message or "unspecified error"


class namespace.AjaxModel extends namespace.Model

  @save: (obj, overwrite=false)->
    # Whether or not the object is in the collection already
    obj = super
    $.post "/data/"+@slug+"/"+obj.get_id(),
        data: JSON.stringify obj
      , ajax_reporter
    obj
    
  # Model.del - delete an object m
  @del: (id)->
    id = super
    $.get "/data/"+@slug+"/"+id+"/del", ajax_reporter

  # Load data from the server.
  @load: (done)->
    
    if remodel.warmup[@slug]
      super remodel.warmup[@slug]
    else
      $.get "/data/"+@slug, (results)=>
        ajax_reporter results # error reporting
        super results


class namespace.LocalStorageModel extends namespace.Model

  @save: (obj, overwrite=false)->
    super
    localStorage[@slug] = JSON.stringify @items

  @del: (id)->
    super
    localStorage[@slug] = JSON.stringify @items

  @load: ->
    items = JSON.parse localStorage[@slug] or '[]'
    super @items


