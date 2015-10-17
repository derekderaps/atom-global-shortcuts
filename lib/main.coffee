{CompositeDisposable} = require 'atom'
remote = require 'remote'
Shortcuts = require './shortcuts'
SelectCommandView = require './select-command-view'
RegisterKeystrokesView = require './register-keystrokes-view'

globalShortcut = remote.require('global-shortcut')

module.exports =

  activate: (state) ->
    @shortcuts = new Shortcuts(globalShortcut)
    @disposables = new CompositeDisposable
    @disposables.add @shortcuts

    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:register-command', =>
      @view = new SelectCommandView (commandName) =>
        @view = new RegisterKeystrokesView({
          commandName: commandName
          shortcuts: @shortcuts
        })

    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:unregister-all', =>
      @shortcuts.unregisterAll()

    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:show-atom-window', ->
      atom.show()

  deactivate: ->
    @view?.cancel()
    @disposables.dispose()
    @disposables = null