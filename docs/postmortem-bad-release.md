# Post-mortem: bad frontend release (drill)

I did this on purpose, to see what happens when a release goes wrong and how fast I'd notice. All times are IST (UTC+05:30).

**Date:** 26 to 27 November 2026
**Time to recover:** about 24 minutes from the bad push (23:53) to the alert clearing in Slack (00:17). Three of those minutes came after I pushed the revert (00:14). I didn't write down the minute I saw every pod Running, so the alert clearing is my marker for "healthy again".
**What customers would have seen:** the old frontend pod stayed `1/1 Running` the whole time, so the store should have kept serving. I wasn't sending test traffic during the drill, so I can't prove there were no errors.

## What I did
I changed `newTag` in `gitops/overlays/dev/kustomization.yaml` to `do-not-exist`, an image tag that was never pushed to ECR, and pushed it to `main`.

## What happened
Only `gitops/` changed, so the CI pipeline didn't run. Argo CD picked up the commit and Kubernetes started a new frontend pod. It couldn't pull the image, so it went to `ErrImagePull`, then `ImagePullBackOff`, and stayed at `0/1`. The old pod kept running, because a rolling update only removes it once the new one is ready. Prometheus fired `PodCannotPullImage` and the alert reached Slack. A built-in alert, `KubePodNotReady`, fired later too.

## Timeline
| Time (IST) | What happened |
|---|---|
| 26 Nov 23:53 | pushed the bad tag |
| 26 Nov 23:53 | new pod went into ErrImagePull, then ImagePullBackOff |
| 26 Nov 23:55 | PodCannotPullImage fired, Slack message arrived |
| 27 Nov 00:05 | Slack said RESOLVED, but the pod was still broken |
| 27 Nov 00:07 | PodCannotPullImage fired again |
| 27 Nov 00:08 | found the cause in the Events of `kubectl describe pod` (I was reading them until about 00:11) |
| 27 Nov 00:10 | KubePodNotReady fired (pod not ready for 15 minutes) |
| 27 Nov 00:14 | ran `git revert HEAD` and pushed |
| 27 Nov 00:17 | PodCannotPullImage resolved, Argo CD had restored the old tag |
| 27 Nov 00:20 | KubePodNotReady resolved |

## Cause
The overlay pointed at an image tag that doesn't exist. Nothing in my setup stops a hand-edited tag from reaching `main`.

## How I found it
`kubectl get pods` showed the new pod stuck in `ImagePullBackOff`. The Prometheus alerts page and the Slack message both named the pod, and the alert text told me to check the image tag in `gitops/overlays/dev`. The Events at the bottom of `kubectl describe pod` confirmed the pull was failing.

Detection was quick: the alert fired about 2 minutes after the push. Getting from the alert to the cause took about 13 more minutes, and that was the slow part. The alert pointed at the right folder but didn't say which tag had failed.

## Fix
`git revert HEAD` and push. Argo CD put the old tag back on its own, with no `kubectl apply`. The alert cleared about 3 minutes after the revert.

## What I'd change
1. Only let the pipeline write image tags, and require a pull request for any change under `gitops/`.
2. Check in CI that the tag exists in ECR before a change can merge.
3. Put the failing image name in the alert text, so the cause is in the Slack message.
4. The alert showed RESOLVED at 00:05 and FIRING again at 00:07 while the pod was still broken. I didn't trace why. My guess is that the pod switches between `ErrImagePull` and `ImagePullBackOff`, my rule matches both as separate series, and for a moment neither was reported. I'd try `keep_firing_for` on the rule so it can't flap.
5. `KubePodNotReady` took 15 minutes to fire. It's a backup, not something to rely on for a bad release.
