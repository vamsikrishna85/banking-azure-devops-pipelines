# Branching and release strategy

Trunk-based development with short-lived branches and release branches for regulated change windows.

| Branch | Purpose | Rules |
|---|---|---|
| `main` | Always releasable trunk | PR only, 2 reviewers, build + SonarQube gate, linked work item |
| `feature/<id>-<slug>` | Short-lived work (< 3 days) | Squash-merged to `main` |
| `release/<major.minor>` | Stabilisation for a CAB window | Cut from `main`; only fixes cherry-picked in |
| `hotfix/<id>` | Urgent production fix | Branched from release tag, merged to `release/*` and `main` |

## Versioning

Semantic versioning (`MAJOR.MINOR.PATCH`). The build number becomes the image tag and the Azure Artifacts package version, so every environment runs an identifiable, immutable artifact.

## Promotion

`DEV` (automatic) → `SIT` (automated regression) → `UAT` (CAB approval + change ticket check) → `PROD` (release manager approval, business-hours check, blue/green swap).

## Rollback

Swap the service selector back to the previous slot (seconds), or redeploy the previous package version from Azure Artifacts (under 15 minutes).
