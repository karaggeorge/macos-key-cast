import * as PCancelable from 'p-cancelable';
import * as asd from 'macos-accessibility-permissions';

declare namespace keyCast {
    /**
    Whether or not this module is supported.
    */
    export const isSupported: boolean;

    /**
    Check if the current app has accessibility permissions.
    If the `ask` parameter is passed as `true`and the permissions are not granted, the user will be prompted.

    @example
    ```
    hasPermissions({ask: true}); // false
    ```

    @param options - Whether to promp the user or not.
    @returns Whether or not the permissions are granted.
    */
    export function hasPermissions(options?: {ask?: boolean}): boolean;
}

/**
Start the key casting proccess.
Returns a cancelable promise.
Call `.cancel()` to stop the process.

@example
```
const keyCastProcess = keyCast({size: 'large'});

keyCastProcess.cancel();
```

@param options - Additional options passed to the CLI.
@returns A cancelable promise to stop the casting.
*/
declare function keyCast(options?: {
    size?: 'small' | 'normal' | 'large';
    delay?: number;
    display?: number;
    keyCombinationsOnly?: boolean;
    bounds?: {
        x: number;
        y: number;
        width: number;
        height: number;
    }
}): PCancelable<void>;

export = keyCast


