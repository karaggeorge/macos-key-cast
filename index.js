const path = require('path');
const execa = require('execa');
const electronUtil = require('electron-util/node');
const macosVersion = require('macos-version');
const PCancelable = require('p-cancelable');
const hasPermissions = require('macos-accessibility-permissions');

const binary = path.join(electronUtil.fixPathForAsarUnpack(__dirname), 'key-cast');

const isSupported = macosVersion.isGreaterThanOrEqualTo('10.14.4');

module.exports = () => new PCancelable(async (resolve, reject, onCancel) => {
	if (!isSupported || !hasPermissions()) {
		resolve();
	}

	const worker = execa(binary);

	onCancel(() => {
		resolve();
		worker.cancel();
	});

	try {
		await worker;
		resolve();
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
