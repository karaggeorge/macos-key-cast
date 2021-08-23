'use strict';
const path = require('path');
const execa = require('execa');
const electronUtil = require('electron-util/node');
const macosVersion = require('macos-version');
const PCancelable = require('p-cancelable');
const hasPermissions = require('macos-accessibility-permissions');

const binary = path.join(electronUtil.fixPathForAsarUnpack(__dirname), 'key-cast');

const isSupported = macosVersion.isGreaterThanOrEqualTo('10.14.4');

module.exports = ({
	size,
	delay,
	display,
	keyCombinationsOnly,
	bounds
} = {}) => new PCancelable(async (resolve, reject, onCancel) => {
	if (!isSupported || !hasPermissions()) {
		resolve();
		return;
	}

	const worker = execa(binary, [
		...(size ? ['-s', size] : []),
		...(delay ? ['-t', delay] : []),
		...(display ? ['-d', display] : []),
		...(
			bounds ? [
				'-b',
				JSON.stringify({bounds: [[bounds.x, bounds.y], [bounds.width, bounds.height]]})
			] : []
		),
		keyCombinationsOnly && '-k'
	].filter(Boolean));

	onCancel.shouldReject = false;
	onCancel(() => {
		resolve();
		worker.cancel();
	});

	try {
		const {stderr} = await worker;
		if (stderr) {
			reject(stderr);
		} else {
			resolve();
		}
	} catch (error) {
		if (error.isCanceled || error.stdout === 'canceled') {
			resolve();
		} else {
			reject(error);
		}
	}
});

module.exports.isSupported = isSupported;

module.exports.hasPermissions = hasPermissions;
