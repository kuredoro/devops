# Continuous Integration best practices

## Interdependent workflows should be located in one file

If you need to test the code on all branches, but push a docker image only on the default branch, don't create two separate workflows that are triggered for different events, since there is no way to establish a sequential continuity between the two different workflows. I.e., in this case we would need to push *only* after we know that test pass, but we wouldn't be able to describe this relation.

Instead one can use conditional steps. In this example the push workflow could be added as a last step to the test workflow that would run only if the branch is default.

In GHA this can be achieved through `if` key.

```yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Get branch name
        id: branch_meta
        run: echo ::set-output name=name::${GITHUB_REF#refs/*/}

      # More steps ...

      - name: Push docker image
        if: ${{ steps.branch_meta.outputs.name == 'main' }}
        run: |
          docker push foo/bar
```

## Never store personal data in YAML files, use secrets

This one is a no brainer, but it's not obvious how to workaround plainly passing the credentials. Well, one can use GitHub repository secrets. They can be defined in the repository settings under "Secrets" section. A secret represents a key-value pair. You can define secrets for 'DOCKERHUB_USERNAME' 'DOCKERHUB_PASSWORD' and other credentials in this way and then use them in place of the actual credential by writing `${{ secrets.SECRET_NAME }}` in YAML file.

## Specify tags inside trigger events

## Use matrix builds for building multiple artifacts

A matrix defines an array of maps. Then a job described in the workflow for which the matrix was defined will be executed for each such map in parallel and the job can depend on the key-value pairs in these maps, like on what it should run on, what parameters to the build process should be passed, how the artifact should be named, etc.

## Prefer actions to shell scripts and intermediate values to environment variables

Actions are already written, tested, and used by many people pieces of code. By reusing them, you're able to spend less time, and increase security of the building process, since the credentials aren't passed around naked in the shell console.

Likewise, it is better not to define environment variables to share information between steps, since they may contain vital information that anyone looking at logs would be able to find out. Prefer intermediate values to them. Define one with shell command (that doesn't actually print anything) `echo ::set-output name=foo::bar`, and access it as `${{ steps.step_name.outputs.foo }}`.

## Disallow the modification of the workflows without code review

## Keep workflow fast

# Jenkins

## Secure Jenkins

By default Jenkins doesn't do any security checks, so a malicious hacker can extract all passwords and get access to the source code.

## Don't run builds on master

Master node is for managing agents and for administration. Running build grants access to the `JENKINS_HOME` directory that contains vital information. Create agents and make sure that the jobs are executed only on them. Jenkins backup *can* be performed on the master node, but be sure to limit *what* jobs can run with `Job restriction plugin`.

## Backup Jenkins home regularly

## Clean the workspace after a job is done

In a Jenkinsfile be sure to add a post step `post { cleanWs() }` to make sure the data created during the build will be erased. Otherwise, you might face storage shortange.
