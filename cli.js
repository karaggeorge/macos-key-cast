#!/usr/bin/env node

const castKeys = require('.');

if (castKeys.hasPermissions({ask: true})) {
	castKeys();
} else {
	console.log('Please enable accessibility permissions');
	process.exit(1);
}