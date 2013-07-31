$ = jQuery

$.widget 'ui.maPlayground',
  options:
    dummy: true

  _create: () ->
    console.log(@options)
    console.log('playground')

