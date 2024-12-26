const { execSync } = require('child_process');
const readline = require('readline');
const fs = require('fs');
const path = require('path');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

async function promptUser(question) {
    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            resolve(answer);
        });
    });
}

async function createRelease() {
    try {
        // Get current version from package.json
        const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, '../package.json')));
        const currentVersion = packageJson.version;
        
        console.log(`Current version: ${currentVersion}`);
        
        // Prompt for new version
        const newVersion = await promptUser('Enter new version (e.g., 1.0.1): ');
        
        // Update package.json
        packageJson.version = newVersion;
        fs.writeFileSync(
            path.join(__dirname, '../package.json'),
            JSON.stringify(packageJson, null, 2)
        );
        
        // Prompt for changelog
        console.log('\nEnter changelog entries (one per line, empty line to finish):');
        const changelog = [];
        while (true) {
            const entry = await promptUser('> ');
            if (!entry) break;
            changelog.push(entry);
        }
        
        // Create changelog file if it doesn't exist
        const changelogPath = path.join(__dirname, '../CHANGELOG.md');
        if (!fs.existsSync(changelogPath)) {
            fs.writeFileSync(changelogPath, '# Changelog\n\n');
        }
        
        // Update CHANGELOG.md
        const date = new Date().toISOString().split('T')[0];
        const changelogContent = fs.readFileSync(changelogPath, 'utf8');
        const newChangelogEntry = `\n## [${newVersion}] - ${date}\n\n${changelog.map(entry => `- ${entry}`).join('\n')}\n`;
        fs.writeFileSync(
            changelogPath,
            changelogContent.replace('# Changelog\n', `# Changelog\n${newChangelogEntry}`)
        );
        
        // Git commands
        console.log('\nCreating git tag and pushing...');
        execSync('git add package.json CHANGELOG.md');
        execSync(`git commit -m "Release v${newVersion}"`);
        execSync(`git tag -a v${newVersion} -m "Version ${newVersion}"`);
        execSync('git push');
        execSync('git push --tags');
        
        console.log(`\nRelease v${newVersion} created successfully!`);
        console.log('GitHub Actions workflow will now build and create the release.');
        console.log('Check the Actions tab on GitHub for progress.');
        
    } catch (error) {
        console.error('Error creating release:', error);
    } finally {
        rl.close();
    }
}

createRelease();
