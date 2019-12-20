# macos-key-cast

> Log keys pressed on macOS. Useful for screen recordings and presentations.

Requires macOS 10.12 or later. macOS 10.13 or earlier needs to download the [Swift runtime support libraries](https://download.developer.apple.com/Developer_Tools/Swift_5_Runtime_Support_for_Command_Line_Tools/Swift_5_Runtime_Support_for_Command_Line_Tools.dmg).

## Run

```
$ npx macos-key-cast
```

## Install

```
$ npm install macos-key-cast
```

## Usage

```js
const castKeys = require('macos-key-cast');

const process = castKeys();

// Later

process.cancel();
```

## Demo

<img src="media/demo.gif">

## Dark Mode support

<img src="media/light.png" height="100">
<img src="media/dark.png" height="100">

## API

### `castKyes(): PCancelable<void>`

Start the process.

The returned promise is an instance of `PCancelable`, so it has a `.cancel()` method which can be used to kill the process

## Limitations

By design, the package only shows special keys and keys that are accompanied by modifiers

If you want to use this and need more features or find a bug, please open an issue and I'll do my best to implement

## Related

- [mac-focus-window](https://github.com/karaggeorge/mac-focus-window) - Focus a window and bring it to the front on macOS
- [mac-windows](https://github.com/karaggeorge/mac-windows) - Provide Information about Application Windows running
- [macos-accessibility-permissions](https://github.com/karaggeorge/macos-accessibility-permissions) - Check and request macOS accessibility permissions

## License

MIT