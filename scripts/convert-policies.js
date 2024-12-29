const fs = require('fs');
const path = require('path');
const { marked } = require('marked');

// Create docs/policies directory if it doesn't exist
const policiesDir = path.join(__dirname, '..', 'docs', 'policies');
if (!fs.existsSync(policiesDir)) {
    fs.mkdirSync(policiesDir, { recursive: true });
}

// Read the template
const template = fs.readFileSync(
    path.join(__dirname, '..', 'docs', 'policies', 'policy-template.html'),
    'utf8'
);

// Read all markdown files from policies directory
const sourceDir = path.join(__dirname, '..', 'policies');
const files = fs.readdirSync(sourceDir).filter(file => file.endsWith('.md'));

files.forEach(file => {
    const markdown = fs.readFileSync(path.join(sourceDir, file), 'utf8');
    const html = marked(markdown);
    
    // Extract title from markdown (first h1)
    const titleMatch = markdown.match(/^#\s+(.+)$/m);
    const title = titleMatch ? titleMatch[1] : file.replace('.md', '');
    
    // Replace placeholders in template
    const finalHtml = template
        .replace('{TITLE}', title)
        .replace('{CONTENT}', html);
    
    // Write the HTML file
    const outputFile = path.join(policiesDir, file.replace('.md', '.html'));
    fs.writeFileSync(outputFile, finalHtml);
    
    console.log(`Converted ${file} to HTML`);
});

console.log('All policies converted to HTML');
