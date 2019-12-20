# macos-key-cast

> Log keys pressed on macOS. Useful for screen recordings and presentations.

Requires macOS 10.12 or later. macOS 10.13 or earlier needs to download the [Swift runtime support libraries](https://support.apple.com/kb/DL1998).

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

const process = castKeys({size: 'large', delay: 1.5, keyCombinationsOnly: true});

// Later

process.cancel();
```

## Demo

<img src="media/demo.gif">

## Dark Mode support

<img src="media/light.png" height="100">
<img src="media/dark.png" height="100">

## API

### `castKyes(options: object): PCancelable<void>`

Start the process.

The returned promise is an instance of `PCancelable`, so it has a `.cancel()` method which can be used to kill the process

#### `options: object`

Additional options passed to the CLI

##### `options.size: 'small' | 'normal' | 'large'`

Default: `normal`

How big the window and the font should be

##### `options.delay: number`

Default: `0.5`

How long the window should remain on screen after the last key press

##### `options.keyCombinationsOnly: boolean`

Default: `false`

Whether or not it should track all key presses or only combinations

## Contributing

If you want to use this and need more features or find a bug, please open an issue and I'll do my best to implement.

PRs are always welcome as well 😃

## Related

- [mac-focus-window](https://github.com/karaggeorge/mac-focus-window) - Focus a window and bring it to the front on macOS
- [mac-windows](https://github.com/karaggeorge/mac-windows) - Provide Information about Application Windows running
- [macos-accessibility-permissions](https://github.com/karaggeorge/macos-accessibility-permissions) - Check and request macOS accessibility permissions

## License

MIT
