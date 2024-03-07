const artifact = require('@actions/artifact');
const glob = require('@actions/glob');

async function run() {
  const artifactClient = artifact.create();
  const globber = await glob.create('**/*.7z.*', {followSymbolicLinks: false});
  const files = await globber.glob();

  for (const file of files) {
    const artifactName = file.split('/').pop();
    console.log(`Uploading ${artifactName}...`);
    await artifactClient.uploadArtifact(artifactName, [file], '.');
  }
}

run().catch(err => console.error(err));