import {expectType, expectError} from 'tsd';
import * as PCancelable from 'p-cancelable';

import * as keyCast from '.';

expectType<PCancelable<void>>(keyCast())
expectType<PCancelable<void>>(keyCast({}))
expectType<PCancelable<void>>(keyCast({size: 'large'}))
expectType<PCancelable<void>>(keyCast({size: 'normal', delay: 1.2}))
expectType<PCancelable<void>>(keyCast({size: 'normal', delay: 1.2, keyCombinationsOnly: true}))

expectError(keyCast({size: 'extra-large'}))
expectError(keyCast({delay: 'long'}))

expectType<boolean>(keyCast.isSupported)