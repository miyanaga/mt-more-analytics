$ = jQuery

$.widget 'ui.maCustomWidget',
  options:
    viewAtFirst: false
    blogId: 0
    magicToken: ''
    cgiUri: ''
    cancelButton: 'Cancel'
    savedMessage: 'Saved'
    jsonParseErrorMessage: 'Parse Error'

  _create: () ->
    @container = $(@element)
    @editor = $(@element).find('.widget-editor')
    @template = @editor.find('.widget-template')
    @switch = $(@element).find('.widget-switch')
    @viewer = $(@element).find('.widget-viewer')
    @viewport = @viewer.find('.widget-viewport')
    @indicator = @viewer.find('.widget-indicator')
    @intro = $(@element).find('.widget-introduction')
    @error = $(@element).find('.widget-error')
    @success = $(@element).find('.widget-success')

    @switch.show()
    @viewer.show()

    @switch.find('.widget-start-edit').click () =>
      @edit()

    @closer = @editor.find('.close')
    @closer.click () =>
      @close()

    @editor.find('.save').click () =>
      @save()

    @editor.find('.preview').click () =>
      @preview()

    @template.bind 'change keyup', () =>
      @dirty(true)

    @view() if @options.viewAtFirst

  _ajax: (action, params, success) ->
    params.__mode = 'ma_custom_widget'
    params.action = action
    params.blog_id = @options.blogId
    params.magic_token = @options.magicToken

    @error.hide().find('.msg-text').text('')
    @success.hide().find('.msg-text').text('')

    @wrap(true)

    $.post( @options.cgiUri, params )
      .fail (jqXHR) =>
        @error.find('.msg-text').text(jqXHR.statusText).show()
      .done (data, jqXHR) =>
        try
          data = $.parseJSON data if typeof data is 'string'
        catch ex
          console.log data
          console.log @options.jsonParseErrorMessage
          @error.show().find('.msg-text').text(@options.jsonParseErrorMessage)
          return

        if data.error?
          @error.show().find('.msg-text').text(data.error)
        else
          if data.result? and data.result.viewport?
            @viewport.html(data.result.viewport).show()
          success.call( @, data.result ) if success?
      .always () =>
        @wrap(false)

  wrap: (flag) ->
    # Cover container semi-transparent
    if flag is true
      $target = @container
      @wrapper = $('<div />')
        .css
          position: 'absolute'
          opacity: 0.5
          'background-color': 'white'
          display: 'none'
          'z-index': 9999

      $target.append(@wrapper)
      @wrapper
        .width($target.width())
        .height($target.height())
        .offset($target.offset())
        .show()

    else if @wrapper?
      @wrapper.remove()

  dirty: (flag) ->
    if flag is true
      @closer.text(@closer.attr('data-cancel-label'))
    else
      @closer.text(@closer.attr('data-close-label'))

  edit: () ->
    @_ajax 'edit', {}, (result) =>
      console.log result
      @template.val(result.template)
      @dirty(false)
      @switch.hide()
      @editor.show()
      @intro.hide()

  close: () ->
    @editor.hide()
    @switch.show()
    @error.hide()
    @success.hide()
    @intro.show()
    @view()

  view: () ->
    @viewport.hide()
    @_ajax 'view', {}, () =>
      @viewport.show()

  save: () ->
    @_ajax 'save', { template: @template.val() }, (result) =>
      @success.show().find('.msg-text').text(@options.savedMessage)
      @intro.remove()
      @dirty(false)

  preview: () ->
    @viewport.hide()
    @_ajax 'preview', { template: @template.val() }, () =>
      @viewport.show()