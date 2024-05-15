const core = require('@actions/core'); const exec = require("@actions/exec");
const process = require('node:process');


async function main() {
  try {
    checkLinux();
    const target = core.getInput('rust_target');
    const target_props = validateTarget(target);
    let arch = getDebianArch(target_props);
    await installDebArch(arch);
    let gccName = getGccName(target_props);
    core.setOutput('linker', gccName)
  } catch (error) {
    core.setFailed(error.message);
  }
}

main();

function checkLinux() {
  if (platform !== 'linux') {
    throw new Error(`This action is only supported on Linux.`);
  }
}

async function installDebArch(arch) {
  core.exportVariable('DEBIAN_FRONTEND', 'noninteractive');
  await exec.exec('sudo', ['apt-get', 'install', `crossbuild-essential-${arch}`]);
}

async function validateTarget(target) {
  if (!target.includes('-unknown-linux-')) {
    throw new Error(`Cross compilation is only supported for Linux targets and hosts.`);
  }

  let targetsStr = ""
  await exec.exec('rustc', ['--print', 'target-list'], {
    listeners: {
      stdout: (data) => {
        targetsStr += data.toString();
      }
    }
  });
  let targets = new Set(targetsStr.split('\n'));

  if (!targets.has(target)) {
    throw new Error(`Not a rust target: ${target}`);
  }

  const split = target.split('-');
  const arch = split[0];
  const other = split[3];
  return { arch, other };
}

function getGccName({ arch, other }) {
  let gccArch = '';
  let gnusuffix = other.replace("musl", "gnu")
  return `gcc-${gccArch}-linux-${gnuSuffix}`;
}

function getDebianArch({ arch, other }) {
  let archMap = {
    'arm': 'arm',
    'aarch64': 'arm64',
    'x86_64': 'amd64',
    'i686': 'i386',
  };
  let archSuffix = {
    'gnueabihf': 'hf',
    'musleabihf': 'hf',
    'gnueabi': 'el',
    'musleabi': 'el',
    'gnu': '',
    'musl': '',
  };
  // check if the architecture is supported
  if (!(arch in archMap)) {
    throw new Error(`Unsupported architecture: ${arch}-${other}`);
  }

  let PACKAGE_ARCH = archMap[arch];
  let ARCH_SUFFIX = archSuffix[other];
  return `${PACKAGE_ARCH}${ARCH_SUFFIX}`;
}
