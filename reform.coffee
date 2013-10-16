
if typeof window isnt 'undefined'
  namespace = window.reform = {}
else
  namespace = module.exports

zpad = retool.zpad

namespace.fields = {}

class namespace.fields.text extends retool.Class
  
  constructor: ->
    super
    unless @name
      console.warn 'unnamed field!', @

  input_type: 'text'
  
  # Is the passed value valid?
  test: (value)->
    valid = true
    if @required and not value
      valid = false
    valid

  # For unbound forms, use #test.
  validate: ->
    value = @value()

    valid = @test value

    # Update DOM error state.
    if valid
      @$state_el().removeClass 'error'
    else
      @$state_el().addClass 'error'
    valid

  # Field child generator
  child: (name, spec={})->
    spec.name = @name + "__" + name
    @form.field_from_spec spec, false
  
  # Specific to fieldset wrapper styles.
  $state_el: ->
    @$el().parents('fieldset')

  $el: ->
    @form.$('[name="'+@name+'"]')

  # Value getter setter
  value: (value)->
    if value
      @$el().val value
    else
      @$el().val()

  _attr_string: (extra_attrs={})->
    h = ''
    attrs = $.extend {}, @attrs,
      name: @name
    , extra_attrs
    for k,v of attrs
      h += ' '+k+'="'+v+'"'
    h
  
  get_label: ->
    if 'function' is typeof @label
      @label()
    else
      @label

  # This method works for single input tags.
  render: (value)->
    h = '<input' 
    h += @_attr_string
      value: value
      type: @input_type
    h+ '>'


class namespace.fields.degrees_minutes_seconds extends namespace.fields.text

  constructor: ->
    super

    @degrees = @child "degrees",
      attrs:
        size: 4
    
    @minutes = @child "minutes",
      attrs:
        size: 4
    
    @seconds = @child "seconds",
      attrs:
        size: 4

  value: ->
    @degrees.value() + @minutes.value / 60 + @seconds.value / 3600

  render: (value)->
    degrees = Math.floor value
    minutes = Math.floor (value - degrees) * 60
    seconds = Math.floor (value - degrees - minutes*60) * 3600
    @degrees.render(degrees) +
      zpad(@minutes.render(minutes),2) + '&deg; '
      zpad(@seconds.render(seconds),2) + ''


class namespace.fields.datetime_split extends namespace.fields.text
  
  constructor: ->
    super

    @date = @child 'date',
      attrs:
        size: 9

    @time = @child 'time',
      attrs:
        size: 4

  
  value: ->
    #date = @form.$field(@date.name).val().match /// (\d\d\d\d) \- (\d\d) \- (\d\d) ///
    #time = @form.$field(@time.name).val().match /// (\d\d) : (\d\d) ///
    (new Date(@date.value() + ' ' + @time.value()).valueOf())


  render: (value)->
    dt = new Date value
    date = zpad(dt.getFullYear(), 4) + '-' + zpad(dt.getMonth() + 1, 2) + '-' + zpad(dt.getDate(), 2)
    time = zpad(dt.getHours(), 2) + ":" + zpad(dt.getMinutes(), 2)

    @date.render(date) + @time.render(time)

  ready: ->
    @$.pickadate()


class namespace.fields.select extends namespace.fields.text
  
  render: (value)->
    
    h = '<select' 
    h += @_attr_string()
    h += '>'
    for option in @get_options()
      selected_flag = if option.value is value then ' selected=selected' else ''
      h += '<option value="' + option.value + '"' + selected_flag + '>' + (option.text ? option.value) + '</option>'
    h += '</select>'
    h

  get_options: ->
    @options ?= APP.MODELS[@model].menu_options_sync()


class namespace.fields.hidden extends namespace.fields.text
  hidden: true
  input_type: 'hidden'

# Typeahead Widget. This should probably be an extension of ReForm, not in core.
class namespace.fields.typeahead extends namespace.fields.hidden
  
  hidden: false # Show the border.

  constructor: ->

    super
    @display = @child "display",
      attrs:
        'class': 'typeahead-display'
        size: @attrs?.size

  render: (value)->
    selected = _.findWhere @get_options(), value: value
    h = super
    h += @display.render selected?.text
    h += "<ul class='typeahead-menu' style='display:none'>"
    for option in @get_options()
      val = option.text ? option.value
      h += "<li class='option' data-value='" + option.value + "'>" + val + "</li>"
    h += "<li class='error' style='display:none'>(no matches)</li>"
    h += "</ul>"
    h

  get_options: ->
    @options ?= remodel.menu_options_sync APP.MODELS[@model].all()


review.view '.typeahead',
  
  get_display: ->
    @$.find '.typeahead-display'

  get_menu: ->
    @$.find '.typeahead-menu'
  
  get_hidden: ->
    @$.find 'input[type="hidden"]'
  
  after: (fn)->
    that = @
    setTimeout ->
      fn.apply that
    , 1

  events:
    
    'click': ->
      unless @get_display().is(":focus")
        @get_display().focus()

    # Field focus styles.
    'focus input': (e)->
      $display = @get_display()
      offs = $display.offset()

      @get_menu().show().css
        top: offs.top - $(window).scrollTop() + $display.outerHeight() + 'px'
        left: offs.left + 'px'
        'max-width': '300px'

      #redraw_typeahead_display.apply @
      @get_menu().children('.option').show()

      @after -> @get_display().get(0).select()

      @update_display_message()

    'blur input': (e)->

      $menu = @get_menu()
      $display = @get_display()
      @update_typeahead_display()
      $current_match = $menu.find 'li.option:visible:first'

      that = @

      setTimeout ->
        $menu.hide()
        
        # Force some the best match to be selected.
        unless $current_match.length
          $menu.find("li:not([data-value])")
        
        if $display.val() isnt $current_match.text()
          that.select_menu_item $current_match
      , 1

    'keyup input': 'update_typeahead_display'

    'mousedown .typeahead-menu': (e)->
      @select_menu_item e.target


  update_typeahead_display: ->

    $t = @get_display()
    $c = $t.next().children('.option').hide()
    v = ($t.val() or '').toLowerCase()
    
    $s = $c.filter(->
      t = @innerText
      pos = t.toLowerCase().indexOf(v)
      if pos > -1
        $(@).html(t.substr(0,pos) + "<b>" +
          t.substr(pos,v.length) + "</b>" +
          t.substr(pos+v.length))
      pos isnt -1
    ).show()

    if $s.length is 0
      @get_menu().find('.error').show()
    else
      @get_menu().find('.error').hide()
    
    @update_display_message()

  update_display_message: ->
    if @get_menu().hasVerticalScrollBar()
      @get_menu().attr('data-message', 'scroll for more')
    else
      @get_menu().attr('data-message', '')

  select_menu_item: (el)->
    @get_display().val $(el).text()
    @get_hidden().val($(el).attr('data-value')).change()
    

# Done the typeahead.

class namespace.fields.textarea extends namespace.fields.text
  render: (value)->
    h = '<textarea' 
    h += @_attr_string()
    h + '>'+(value or '')+'</textarea>'


class namespace.fields.number extends namespace.fields.text
  input_type: 'number'
  value: (value)->
    val = super
    if val then return parseInt val



namespace.form = (root, opts={})->

  opts.root = root

  # A form handle presents various ways to interact with the form.
  form = new namespace.form.Form opts
  form.fields = []
  
  for field in opts.fields
    form.field_from_spec field

  form.view = review.view root,

    events:
      'change *[name]': 'change'

    change: (e)->
      @form.change e

    form: form

  form

# Generate a form for a particular model.
# This currently just adds an id field.
namespace.model_form = (root, opts={})->
  
  # Add an id attribute automatically if it's not there.
  id_fields = _.where opts.fields, name: opts.model.id_attr
  unless id_fields.length
    opts.fields.unshift {name: opts.model.id_attr, type: 'hidden'}
  namespace.form root, opts

class namespace.form.Form extends retool.Class
  
  # Generate a field object from a spec, and optionally add it to this form's root.
  field_from_spec: (spec, is_root=true)->
    fieldClass = namespace.fields[spec.type or 'text']
    spec.form = @
    field = new fieldClass spec
    if is_root then @fields.push field
    field

  # A form may be bound to a piece of the DOM.
  is_bound: ->
    not not @root

  $: (subSelector)->
    $el = $(@root).filter(":visible")
    if subSelector then return $el.find subSelector
    $el

  get_field: (fieldname)->

    field = _.findWhere @fields, name: fieldname
    field

  # REFACTOR - This is App specfiic. Take it out of this shared lib.
  render_field: (field, value)->
    if field.hidden then return field.render value
    h = '<fieldset class="'
    unless field.test value
      h += "error "
    h += field.constructor.name + '">'
    if field.label
      h += '<legend>' + field.get_label() + '</legend>'
    h += field.render value
    h + '</fieldset>'
  # END REFACTOR

  render: (data)->
    throw "No data" unless data
    h = ''
    for field in @fields
      h += @render_field field, data[field.name]
    h

  generate: (data)->
    
    $h = $(@render(data))
    $h.find('input').filter(->
        $(@).attr('name').indexOf("__date") isnt -1
      ).pickadate
        formatSubmit: 'yyyy-mm-dd'
        format: 'yyyy-mm-dd'
    $h

  get_data: ->

    data = {}
    for field in @fields
      data[field.name] = field.value()
    data

  # Bound forms only.
  validate: ->
    valid = true
    for field in @fields
      valid = valid and field.validate()
    valid

  _get_truncated_name: (el)->
    name = $(el).attr('name')
    end = name.indexOf('__') # Double underscore signifies sub-fields.
    if end is -1
      name
    else
      name.substr(0, end)

  # Pass in a field change event.
  change: (e)->
    fieldname = @_get_truncated_name e.target
    field = @get_field fieldname
    field.validate()
    if @model?
      instance = new @model(@get_data())
      instance.save()

  # Save the current bound form data.
  save: ->
    @model.save @get_data()
