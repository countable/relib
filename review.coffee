

if typeof window isnt 'undefined'
  namespace = window.review = {}
else
  namespace = module.exports

$doc = $(document)

# Common view methods.
base_view = {}

namespace.view = (root, opts)->
  opts.__proto__ = base_view
  
  generate_view = (e, el)->
    $root = $(el)
    unless $root.is(root)
      $root = $root.parent(root)
    view_instance =
      $: $root
      el: el
      target: e.target
    view_instance.__proto__ = opts
    view_instance

  # Delegate handling an event desribed by @param specifier to @param handler.
  delegate = (specifier, handler)->

    tokens = specifier.split(' ')
    event_type = tokens[0]
    selectors = [root].concat(tokens[1..]).join(' ')

    if 'string' is typeof handler
      handler = opts[handler]
    
    $doc.on event_type, selectors, (e)->
      # Apply a handler to our view.
      # Notably, we create a new instance of the view at this time which serves as a context for the event handler.
      view_instance = generate_view e, @
      handler.call view_instance, e

  $.each opts.events, delegate
