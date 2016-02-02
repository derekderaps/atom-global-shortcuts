{CompositeDisposable} = require 'atom'
remote = require 'remote'
Shortcuts = require './shortcuts'
SelectCommandView = require './select-command-view'
RegisterKeystrokesView = require './register-keystrokes-view'
RegisteredCommandsView = require './registered-commands-view'
globalShortcut = remote.require('global-shortcut')

module.exports =

  activate: (state) ->
    console.log 'state', state
    @shortcuts =
      # Use serialized state to recreate previously-registered global shortcuts.
      if state
        # Stuff globalShortcut into state rather than having it serialized.
        state.data.globalShortcut = globalShortcut
        atom.deserializers.deserialize(state)
      else
        # No previously-registered global shortcuts.
        new Shortcuts globalShortcut

    @disposables = new CompositeDisposable
    @disposables.add @shortcuts

    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:register-command', =>
      @view = new SelectCommandView (commandName) =>
        @view = new RegisterKeystrokesView({
          commandName: commandName
          shortcuts: @shortcuts
        })

    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:registered-commands', =>
      @view = new RegisteredCommandsView(@shortcuts)
    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:unregister-command', =>
      @view = new RegisteredCommandsView(@shortcuts)

    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:unregister-all', =>
      @shortcuts.unregisterAll()

    # Create a command to show/hide the Atom window.
    @disposables.add atom.commands.add 'atom-workspace', 'global-shortcuts:show-atom-window', ->
      # Is the window currently visible?
      currentWindow = atom.applicationDelegate.getCurrentWindow()
      if currentWindow.isVisible()
        # Determine which Atom window is focused, and store it for later.
        for browserWindow in remote.require('browser-window').getAllWindows()
          @activeWindow = browserWindow if browserWindow.isFocused()
        # Use the active view to call "Hide Application".
        pane = atom.workspace.getActivePane()
        view = atom.views.getView(pane)
        atom.commands.dispatch(view, 'application:hide')
      else
        # Atom is not visible, so "show" the previously-focused window.
        currentWindow.show()
    return

  # Serializes the "Shortcuts" object.
  serialize: ->
    @shortcuts.serialize()

  deactivate: ->
    @view?.cancel()
    @disposables.dispose()
    @disposables = null
