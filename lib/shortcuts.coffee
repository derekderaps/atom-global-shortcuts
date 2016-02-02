_ = require 'underscore-plus'

module.exports =
class Shortcuts

  # Tell Atom we want to support serialization of this class.
  atom.deserializers.add(this)

  # Re-registers all our serialized commands.
  @deserialize: ({data}) ->
    new Shortcuts data.globalShortcut data.registered

  # Optionally accepts a parameter of shortcuts to register immediately.
  constructor: (@globalShortcut, shortcuts) ->
    @registered = []
    @registerCommand shortcut.keystrokes, shortcut.commandName, true for shortcut in shortcuts if shortcuts

  # Serializes the array of "registered" shortcuts.
  serialize: ->
    deserializer: 'Shortcuts',
    data:
      registered: @registered

  isRegistered: (keystrokes) =>
    try
      @globalShortcut.isRegistered(@accelerator(keystrokes))
    catch
      null #aka don't know

  registerCommand: (keystrokes, commandName, preventNotify) ->
    accelerator = @accelerator(keystrokes)
    didRegister =
      try
        @globalShortcut.register accelerator, ->
          atom.commands.dispatch(atom.views.getView(atom.workspace), commandName)
      catch
        false

    if didRegister
      @registered.push(
        commandName: commandName
        keystrokes: keystrokes
      )
      # Only notify the user when shortcut registered manually. I.e., don't
      # notify about shortcuts re-registered on startup.
      atom.notifications.addSuccess "global-shortcuts: Registered command!", {
        detail: "#{_.humanizeKeystroke(keystrokes)} will trigger #{commandName}!"
      } if (!preventNotify)
    else
      console.warn "global-shortcuts: Could not register #{accelerator} as global shortcut (keystrokes: #{keystrokes})"
    didRegister

  unregister: (item) ->
    @registered.splice(@registered.indexOf(item), 1)
    @globalShortcut.unregister(@accelerator(item.keystrokes))
    atom.notifications.addSuccess "global-shortcuts: Unregistered #{item.keystrokes}!"

  unregisterAll: ->
    @globalShortcut.unregisterAll()
    @registered = []
    atom.notifications.addSuccess "global-shortcuts: Unregistered all!"

  dispose: ->
    @unregisterAll()

  accelerator: (keystrokes) ->
    keystrokes.replace(/-/g, '+').replace('cmd', 'CmdOrCtrl')
