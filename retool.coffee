

if typeof window isnt 'undefined'
  namespace = window.retool = {}
else
  namespace = module.exports


# Fetch an object id from a DOM node by walking parents for an associated element.
# If the optional @param model is provided, return an object with that id instead.
# The associated DOM node should have an attribute data-item-id if no model is specified, or data-<slug>-id
# where <slug> is the lowercase slug for that model.
#
# @param {object} model - should have a "get" method, and either a "slug" attribute or "name" attribute.
$.fn.item = (model)->

  node = $(@).get(0)
  if 'string' is typeof model then model = {slug:model}
  if model
    slug = (model.slug or model.name?.toLowerCase())
  else
    slug = 'item'

  while node and node.tagName isnt 'HTML'
    id = node.getAttribute('data-'+slug+'-id')
    if id?
      if model.get and model.id_attr # If a real model was passed, find instance.
        return model.get id
      else
        return id
    node = node.parentNode

  null


# Same as $.fn.empty() but ensures "remove" is called on all children.
$.fn.emptyAll = ->
  $(@).children().remove()
  $(@).text('')


$.fn.hasVerticalScrollBar = -> @[0].clientHeight < @[0].scrollHeight


namespace.zpad = (s='', n=0)->
  s += ''
  while s.length < n
    s = '0' + s
  s



class namespace.Class
  constructor: (o)->
    for k,v of o
      @[k] = v


###
# Python style imports for javascript / coffeescript. Import module contents into your scope.
# This is like python's "from APP.MODULE import *" pattern.

APP = require 'APP' # If using Node or other commonjs imports.

eval MODULE 'APP.MY_MODULE' # The "magic"

# Then you can do:
amazing = new Amazing()

class APP.MY_MODULE.Amazing =
  shine: ->

amazing = new APP.MODULE.Amazing()

# You can also define modules like this:

MODULE 'APP.MY_MODULE', ->
  class @Amazing
    shine ->


# response: Wow! You did the same thing with more code...
# Yes, it's probably better to just use explicit references to modules.
###

window.MODULE = (names, fn) ->
  if fn
    names = names.split '.' if typeof names is 'string'
    space = @[names.shift()] ||= {}
    space.MODULE ||= @MODULE
    if names.length
      space.MODULE names, fn
    else
      fn.call space
  else
    items = []
    for k,v of eval(names)
      if k isnt 'MODULE'
        items.push k + '=' + names + '.' + k
    'var ' + items.join(',') + ';'  




