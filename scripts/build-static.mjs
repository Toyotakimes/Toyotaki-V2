import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

// Publish only the MES frontend, never SQL, credentials, tools or local test files.
const files = execFileSync('git', ['ls-files', '-z'], { encoding: 'utf8' })
  .split('\0').filter(file => /^[^/]+\.html$/.test(file) || /^shared\/.+\.(html|js|css|ttf|woff2|txt)$/.test(file));
const output = path.resolve('.deploy/site');
fs.mkdirSync(output, { recursive: true });
for (const file of files) {
  const destination = path.join(output, file);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.copyFileSync(file, destination);
}
console.log(`Prepared ${files.length} frontend assets in ${output}`);
