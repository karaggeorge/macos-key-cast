import {expectType, expectError} from 'tsd';
import * as PCancelable from 'p-cancelable';

import * as keyCast from '.';

expectType<PCancelable<void>>(keyCast())
expectType<PCancelable<void>>(keyCast({}))
expectType<PCancelable<void>>(keyCast({size: 'large'}))
expectType<PCancelable<void>>(keyCast({size: 'normal', delay: 1.2}))
expectType<PCancelable<void>>(keyCast({size: 'normal', delay: 1.2, keyCombinationsOnly: true}))
expectType<PCancelable<void>>(keyCast({size: 'normal', delay: 1.2, keyCombinationsOnly: true, display: 123}))

expectError(keyCast({size: 'extra-large'}))
expectError(keyCast({delay: 'long'}))
expectError(keyCast({display: '123'}))

expectType<boolean>(keyCast.isSupported)