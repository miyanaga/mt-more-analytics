$ = jQuery

$.widget 'ui.maPlayground',
  options:
    blogId: 0
    cgiUri: ''
    metrics: {}
    dimensions: {}
    unknownLabel: 'Unknown'
    indexLabel: '#'

  _create: () ->

    @container = @element
    @metrics = {}
    @dimensions = {}
    @sorts = {}

    @current = {}
    @current.metrics = []
    @current.dimensions = []
    @current.sort = []

    # Mapping metrics and dimensions
    $.each @options.metrics, (k, lex) =>
      label = k + ':' + lex.l + '#' + lex.g
      @metrics[label] = true

    $.each @options.dimensions, (k, lex) =>
      label = k + ':' + lex.l + '#' + lex.g
      @dimensions[label] = true

    # Other profiles
    $.post @options.cgiUri,
      __mode: 'ma_profiles'
      blog_id: @options.blogId
    .done (data, jqXHR) =>
      $profiles = @container.find('.ids')
      $profiles.append($(data).children())
    .fail (jqXHR) =>
      console.log(jqXHR)

    @tagify()

    @container.find('.api-param').on 'change', () =>
      @reload()

    @container.find('.reload').click () =>
      @reload()

  reload: () ->
    @updateTemplateSnipet()
    @updateListing()

  _simpleTagify: (cls, opts = {}) ->
    @container.find(cls).textext
      plugins: 'tags autocomplete'
    .on
      getSuggestions: (e, data) ->
        hash = {}
        hash = opts.hasher() if opts.hasher?

        re = new RegExp(data.query, 'i')
        results = []
        $.each hash, (l, v) =>
          results.push l if l.match(re)

        $(@).trigger 'setSuggestions',
          result: results
          showHideDropdown: true
      isTagAllowed: (e, data) ->
        hash = {}
        hash = opts.hasher() if opts.hasher?
        data.result = hash[data.tag] or false
      getFormData: (e, data) ->
        current = data[200].form
        opts.updater(current) if current? and opts.updater?

  tagify: () ->
    # Metrics
    @_simpleTagify '.metrics',
      hasher: () =>
        @metrics
      updater: (current) =>
        if @current.metrics.join(',') != current.join(',')
          @current.metrics = current
          @reload()

    # Dimensions
    @_simpleTagify '.dimensions',
      hasher: () =>
        @dimensions
      updater: (current) =>
        if @current.dimensions.join(',') != current.join(',')
          @current.dimensions = current
          @reload()

    # Sort
    @_simpleTagify '.sort',
      hasher: () =>
        hash = {}
        $.each [@current.metrics, @current.dimensions], (i, a) ->
          $.each a, (j, v) ->
            hash[v] = true
            hash['-' + v] = true
        hash
      updater: (current) =>
        if @current.sort.join(',') != current.join(',')
          @current.sort = current
          @reload()

  tagifiedKeys: (cls) ->

    # Collect keys from tag elements
    $els = @container.find(cls).textext()[0].tags().tagElements()
    cols = []
    $els.find('span.text-label').each () ->
      cols.push $(@).text()

    normalized = []
    $.each cols, (i, c) ->
      if c.match(/^(-?[a-z0-9]+)/i)
        normalized.push RegExp.$1

    normalized

  getParams: () ->

    params = {}

    # Single values
    $.each ['ids', 'period', 'filters', 'start-index', 'max-results'], (i, id) =>
      console.log id
      cls = '.' + id
      v = @container.find(cls).val()
      return if v is null or v is undefined

      v = v.replace(/\n/g, '')
      return if v.length < 1

      p = id.replace(/-/g, '_')
      params[p] = v

    $.each @current, (k, arr) ->
      values = []
      $.each arr, (i, f) ->
        if f.match(/^(-?[a-z0-9]+)/i)
          values.push RegExp.$1
      v = values.join(',')
      return if v is null or v.length < 1

      params[k] = v


    console.log params
    params

  updateTemplateSnipet: () ->

    params = @getParams()
    metrics = @current.metrics
    dimensions = @current.dimensions
    all = dimensions.concat metrics

    # Attributes
    attrs = []
    $.each params, (k, v) =>
      return if k == 'period' and v == 'default'
      attrs.push k + '="' + v + '"'

    # Build template
    lines = []
    lines.push '<' + 'mt:GAReport ' + attrs.join(' ') + '>'

    # Report values
    values = []
    $.each all, (i, k) =>
      if k.match(/^(-?[a-z0-9]+)/i)
        k = RegExp.$1
      else
        return

      lex = @options.metrics[k] || @options.dimensions[k]
      l = lex.l + '(' + lex.g + ')' if lex?
      l = 'Unknown' unless lex?
      values.push l + ': <' + '$mt:GAValue name="' + k + '"$>'

    if values.length > 0
      lines.push ''
      lines = lines.concat values
      lines.push ''

    # Close tag
    lines.push '</' + 'mt:GAReport' + '>'

    @container.find('.template-snipet').val(lines.join("\n"))

  _showQueryError: (msg) ->
    @container.find('.query-error').removeClass('hidden').find('.msg-text').text(msg)

  updateListing: () ->
    params = @getParams()
    params.__mode = 'ma_playground_query'
    params.blog_id = @options.blogId

    # Hide error
    @container.find('.query-error').addClass('hidden')
    @container.find('.reload').addClass('hidden');
    @container.find('.loading').removeClass('hidden');

    # Remove all headers
    $headers = @container.find('.listing-thead-row')
    $headers.children().remove()

    # Remove all rows
    $tbody = @container.find('.listing-tbody')
    $tbody.children().remove()

    $.post( @options.cgiUri, params )
    .always (jqXHR) =>
      @container.find('.reload').removeClass('hidden');
      @container.find('.loading').addClass('hidden');
    .fail (jqXHR) =>
      @_showQueryError jqXHR.statusText
    .done (data, jqXHR) =>
      if data.error?
        @_showQueryError data.error
        return

      console.log data

      # Headers
      $th = $('<th class="col head cb"><span class="col-label" /></th>')
      $th.find('.col-label').text(@options.indexLabel)
      $headers.append $th

      $.each data.result.headers, (i, h) =>
        $th = $('<th class="col head"><div class="col-label key" /></th>')
        $th.find('.key').text(h)
        lex = @options.metrics[h] || @options.dimensions[h]
        if lex?
          label = lex.l + '(' + lex.g + ')'
          $th.append($('<div class="col-label label" />').text(label))
        $headers.append $th

      # Values
      $.each data.result.items, (i, item) =>
        $tr = $('<tr />')

        $td = $('<td class="col" />').text(i + 1)
        $tr.append $td

        $.each data.result.headers, (j, h) =>
          $td = $('<td class="col" />').text(item[h])
          $tr.append $td
        $tbody.append $tr

