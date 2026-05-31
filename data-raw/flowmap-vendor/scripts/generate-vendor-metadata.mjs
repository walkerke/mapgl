import {createHash} from 'node:crypto';
import {access, readdir, readFile, writeFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const outputDir = process.argv[2];
const licenseNotePath = process.argv[3];

if (!outputDir || !licenseNotePath) {
  throw new Error(
    'Usage: node scripts/generate-vendor-metadata.mjs <output-dir> <license-note-path>'
  );
}

const vendorDir = fileURLToPath(new URL('../', import.meta.url));
const lockPath = path.join(vendorDir, 'package-lock.json');
const packagePath = path.join(vendorDir, 'package.json');
const patchesDir = path.join(vendorDir, 'patches');
const bundleName = 'flowmap-gl-bundle.min.js';
const manifestName = 'flowmap-gl-vendor-manifest.json';
const additionalBundledPackages = [
  {
    name: 'd3',
    version: '7.9.0',
    license: 'ISC',
    repository: 'https://github.com/d3/d3.git'
  },
  {
    name: 'lil-gui',
    version: '0.19.0',
    license: 'MIT',
    repository: 'https://github.com/georgealways/lil-gui'
  }
];
const patchPurposes = {
  'patches/flowmap-temporal-scale-domain.patch':
    'Add temporalScaleDomain so temporal flow width/color domains can use selected-time or all-time flows.'
};

const [lock, packageJson, bundle] = await Promise.all([
  readJson(lockPath),
  readJson(packagePath),
  readFile(path.join(outputDir, bundleName))
]);
const colorSchemes = extractColorSchemes(bundle.toString('utf8'));
const patchMetadata = await getPatchMetadata();

const declaredDependencies = packageJson.dependencies;
const packages = await Promise.all(
  Object.entries(lock.packages)
    .filter(([packagePath]) => packagePath.startsWith('node_modules/'))
    .map(async ([packagePath, metadata]) => {
      const name = packagePath.replace(/^node_modules\//, '');
      const packageJsonPath = path.join(vendorDir, packagePath, 'package.json');
      if (!(await exists(packageJsonPath))) {
        return null;
      }

      const packageJson = await readJson(packageJsonPath);
      return {
        name,
        version: metadata.version,
        license: packageJson.license ?? packageJson.licenses ?? metadata.license ?? null,
        integrity: metadata.integrity ?? null,
        resolved: metadata.resolved ?? null,
        gitHead: packageJson.gitHead ?? null,
        homepage: packageJson.homepage ?? null,
        repository: normalizeRepository(packageJson.repository)
      };
    })
);

const installedPackages = packages.filter((pkg) => pkg !== null);
installedPackages.sort((a, b) => a.name.localeCompare(b.name));

const directPackages = Object.keys(declaredDependencies)
  .sort()
  .map((name) => {
    const metadata = installedPackages.find((pkg) => pkg.name === name);
    if (!metadata) {
      throw new Error(`Missing lockfile metadata for ${name}`);
    }
    return metadata;
  });

const manifest = {
  schemaVersion: 1,
  source: 'npm release packages',
  build: {
    command: 'data-raw/flowmap-vendor/build-flowmap.sh build',
    node: execFileSync('node', ['--version'], {encoding: 'utf8'}).trim(),
    npm: execFileSync('npm', ['--version'], {encoding: 'utf8'}).trim(),
    esbuild: declaredDependencies.esbuild
  },
  bundle: {
    path: 'inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js',
    sha256: createHash('sha256').update(bundle).digest('hex'),
    bytes: bundle.byteLength
  },
  patches: patchMetadata,
  copyrights: {
    path: 'LICENSE.note'
  },
  colorSchemes: {
    source: 'FlowMapGL 9.3.0 vendored bundle',
    names: colorSchemes
  },
  directDependencies: directPackages,
  transitiveDependencies: installedPackages.filter(
    (pkg) => !Object.hasOwn(declaredDependencies, pkg.name)
  )
};

await writeFile(
  path.join(outputDir, manifestName),
  `${JSON.stringify(manifest, null, 2)}\n`
);

await writeFile(licenseNotePath, renderLicenseNote(installedPackages));

async function readJson(file) {
  return JSON.parse(await readFile(file, 'utf8'));
}

async function exists(file) {
  try {
    await access(file);
    return true;
  } catch {
    return false;
  }
}

async function getPatchMetadata() {
  if (!(await exists(patchesDir))) {
    return [];
  }

  const patchNames = (await readdir(patchesDir))
    .filter((name) => name.endsWith('.patch'))
    .sort();

  return Promise.all(
    patchNames.map(async (name) => {
      const patchPath = path.join(patchesDir, name);
      const contents = await readFile(patchPath);
      const relativePath = `data-raw/flowmap-vendor/patches/${name}`;
      const purposeKey = `patches/${name}`;
      return {
        path: relativePath,
        sha256: createHash('sha256').update(contents).digest('hex'),
        bytes: contents.byteLength,
        purpose: patchPurposes[purposeKey] ?? ''
      };
    })
  );
}

function normalizeRepository(repository) {
  if (!repository) {
    return null;
  }

  if (typeof repository === 'string') {
    return repository;
  }

  return repository.url ?? null;
}

function extractColorSchemes(bundle) {
  const match = bundle.match(
    /(?:^|[;,])[$A-Z_a-z][\w$]*=\{(Blues:[\s\S]*?YlOrRd:[^}]+?)\},[$A-Z_a-z][\w$]*=Object\.keys\(/
  );

  if (!match) {
    throw new Error('Could not find FlowMapGL color schemes in the bundle');
  }

  const names = [...match[1].matchAll(/([A-Za-z][A-Za-z0-9]*):/g)].map(
    (scheme) => scheme[1]
  );

  for (const required of ['Blues', 'Teal', 'Viridis', 'YlOrRd']) {
    if (!names.includes(required)) {
      throw new Error(`Missing expected FlowMapGL color scheme: ${required}`);
    }
  }

  return names;
}

function renderLicenseNote(packages) {
  return [
    'This package as a whole is licensed under the MIT License (see LICENSE file).',
    '',
    'It bundles several third-party JavaScript components. The FlowmapGL browser bundle shipped at `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js` is generated from npm release packages by `data-raw/flowmap-vendor/build-flowmap.sh build`.',
    '',
    'Below are the licenses of the individual bundled components:',
    '',
    '| Package | Version | License | Source |',
    '| --- | --- | --- | --- |',
    ...renderCopyrightRows(packages),
    ''
  ].join('\n');
}

function renderCopyrightRows(packages) {
  const allPackages = [...packages, ...additionalBundledPackages];
  allPackages.sort((a, b) => a.name.localeCompare(b.name));

  return allPackages.map((pkg) => {
    const license = renderLicense(pkg.license);
    const source = pkg.repository ?? pkg.homepage ?? pkg.resolved ?? '';
    return `| ${pkg.name} | ${pkg.version} | ${license} | ${source} |`;
  });
}

function renderLicense(license) {
  if (!license) {
    return '';
  }

  if (typeof license === 'string') {
    return license;
  }

  if (Array.isArray(license)) {
    return license.map(renderLicense).join(', ');
  }

  return license.type ?? JSON.stringify(license);
}
