# Contributing to Codename

With your fork, you can make pull requests if you want to fix a bug or add a feature to the game. To do this, once the changes you have are pushed to your repository in GitHub, do the following:

1. On the main page of your repository, click the contribute button. This will open the page for making pull requests.
2. Enter a name and a description for your PR. By default, the title will be the first line of the most recent commit message, and an empty description.
3. Click the green button on the bottom that says `Create pull request`. If this is a work in progress, then click the chevron next to it and select `Draft pull request`. That way, the PR you have opened cannot be merged until it is ready for review.

Once opened, you are taken to the page of the origin's repository (which is the repository you forked from) where the pull request you just made will keep track of any future commits you make on your fork until it is closed (with or without it getting merged).

## Ensuring your fork is up to date

You may have seen a modal on the main page of your fork that says something along the lines of
> This branch is N commits ahead of and M commits behind `CodenameEngine/main`.

as well as a button that says `Sync fork`. **You should not sync just yet**.

`N commits ahead of` are commits that are present in your fork that the origin doesn't have. `M commits behind` is the other way around, those being commits in the origin your fork lacks.

There are two ways to keep your fork up to date: **merging** and **rebasing**.

### Merging

Merging is simply introducing the origin's commits to your fork's tree as a single commit containing the commits that you're behind. This is generally the safest and easiest option of the two.

To do so, head to your main page of the repository, click `Sync fork`, then click `Update branch`.

### Rebasing

> [!WARNING]
> Rebasing rewrites your tree, which is often seen as destructive. This should only be done if you're the only person to work in this fork.

<details>
	<summary>TL;DR: Rebasing</summary>

Assuming your remotes are configured, follow one of the following:

For GitHub Desktop:
1. Click `Branch` > `Rebase current branch...` / Hit `CTRL`+`SHIFT`+`E`
2. Pick the original repo's branch and click `Rebase`

For Git CLI:
```bash
git fetch upstream
git checkout primary
git rebase upstream/main
git push --force-with-lease
``` 

For GitHub CLI:
```bash
gh pr update-branch --rebase
```

</details>
</br>

Rebasing tells Git that you want your PR to start off later in the origin, and it does this by setting your commits aside, applies commits from the origin, and reapplies your commits. This results in a more linear commit history, and is **the recommended method** when working with PRs as this puts your commits *after* the ones from the origin.

To begin rebasing, you need to configure your remotes. See [this](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/configuring-a-remote-repository-for-a-fork) guide for instructions on this.

#### Method 1: GitHub Desktop
Rebasing in GitHub Desktop involves a two step process:

1. Click `Branch` > `Rebase current branch...` / Hit `CTRL`+`SHIFT`+`E`
2. Select which branch you want to use to pull commits from. This is usually in your upstream's default branch.

#### Method 2: Git CLI

Assuming you've named the original repository as `upstream` and your fork's branch is named `primary`, here are the steps:
1. Fetch the branches and their commits with `git fetch upstream`.
2. Checkout your fork's branch with `git checkout primary`.
3. Rebase with `git rebase upstream/main`.
4. Push with `git push --force-with-lease`. Since rebasing changes history, the push must be forced.

#### Method 3: GitHub CLI
The GitHub CLI (nope, this one is different from Git) allows you to update a branch from its base branch.

You can do this by running the below command:
```bash
gh pr update-branch --rebase
```

### Dealing with merge conflicts
If you've noticed that you're unable to sync your fork, this means that a merge conflict has appeared.

This happens if two people edit the same lines in the same file at the same time. Git cannot differentiate whose edits would be merged and aborts.

The GitHub docs provides [an article](https://docs.github.com/en/pull-requests/reference/merge-conflicts) on how to reconcile these.