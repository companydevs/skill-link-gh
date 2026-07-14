const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const readme = fs.readFileSync('README.md', 'utf8');
const outputDir = 'docs/diagrams';

// Match all mermaid blocks and their preceding heading
const headingRegex = /###\s+((?:Diagram|Figure)\s+[\d.]+[^#\n]*)\n[\s\S]*?```mermaid\n([\s\S]*?)```/g;

let match;
let count = 0;

while ((match = headingRegex.exec(readme)) !== null) {
  const rawTitle = match[1].trim();
  const diagramCode = match[2].trim();

  // Build a safe filename from the heading
  const safeName = rawTitle
    .replace(/[^a-zA-Z0-9\s]/g, '')   // remove special chars
    .replace(/\s+/g, '_')              // spaces to underscores
    .replace(/_+/g, '_')               // collapse multiple underscores
    .toLowerCase()
    .substring(0, 60);

  const mmdFile = path.join(outputDir, `${safeName}.mmd`);
  const pngFile = path.join(outputDir, `${safeName}.png`);

  fs.writeFileSync(mmdFile, diagramCode, 'utf8');

  try {
    execSync(
      `mmdc -i "${mmdFile}" -o "${pngFile}" -w 1600 -H 900 -b white --puppeteerConfigFile .github/scripts/puppeteer-config.json --quiet`,
      { stdio: 'inherit' }
    );
    console.log(`Rendered: ${pngFile}`);
    count++;
  } catch (err) {
    console.error(`Failed to render: ${rawTitle}`);
    console.error(err.message);
  }

  // Clean up temp .mmd file
  fs.unlinkSync(mmdFile);
}

console.log(`\nDone. ${count} diagrams rendered to ${outputDir}/`);
