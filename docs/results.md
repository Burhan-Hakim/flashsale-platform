# Results

All numbers are from my own run on 26 to 27 November 2026. Times are IST (UTC+05:30).

| Measurement | Result |
|---|---|
| terraform apply (61 resources) | 11 minutes (15:00 to 15:11) |
| git push to new version running (idle cluster) | about 6 minutes (18:38 to 18:44) |
| Trivy blocked a vulnerable image | yes, twice (6 HIGH Go findings, then a CRITICAL zlib CVE in an old Alpine image) |
| Load test, 100 users, 3 minutes: requests | 11,108 |
| Load test: requests per second | 61.71 |
| Load test: failed requests | 0 |
| Load test: time per request | mean 1.61 s, median 1.61 s, 95% within 1.93 s, slowest 2.71 s |
| Frontend pods at peak (limit is 5) | 5 |
| Time to scale from 1 to 5 pods | about 1 minute (1, 2, 4, then 5). Each new pod was Ready in about 11 seconds |
| Scale-down after the test | 5 to 1 in one step, about 5 minutes after the load stopped |
| Release during a 10-minute load test: requests | 36,125 at 60.21 per second (the frontend started this test already at 5 pods) |
| Release during the load test: real errors | 0 connect, 0 receive, 0 exceptions, 0 non-2xx |
| Release during the load test: length mismatches | 5,511 (ApacheBench counts these as "failed") |
| Release during the load test: push to live | about 8 minutes (22:47 to 22:55). The test ended at about 22:55, so the release landed in its last minute or two |
| Bad release: deploy to alert | about 2 minutes (23:53 to 23:55) |
| Bad release: deploy to cause found | about 15 minutes (23:53 to 00:08) |
| Bad release: deploy to revert pushed | about 21 minutes (23:53 to 00:14) |
| Bad release: revert pushed to alert cleared | about 3 minutes (00:14 to 00:17) |
| Bad release: deploy to alert cleared | about 24 minutes (23:53 to 00:17) |
| Cluster lifetime | about 9.5 hours |
| Approximate cost of the lab | about $6.3 (AWS month-to-date, 1 to 27 Nov) |

## Notes on the numbers

- **The autoscaler worked, the store wasn't fast.** Zero failed requests at 100 users is the good part. About 1.6 s per request is slow. The frontend hit its 5-pod cap in both tests.
- **Scaling speed.** Pods start in about 11 seconds, so the delay before 5 pods came from the metrics lag, not pod startup.
- **Scale-down.** The autoscaler waited about 5 minutes (its default stabilisation window), then dropped from 5 pods to 1.
- **My first attempt at the release test.** I started it at 22:40 and cancelled it with Ctrl+C. It had already scaled the frontend up, so the real test (22:45) began with 5 pods running. I worked this out afterwards from the pod ages and the alert timing, so it's an inference. It means that test shows a release under load, not scale-out.
- **`KubeHpaMaxedOut`.** Slack got this at 22:57 and the resolved message at 23:02. The alert means "at max replicas for over 15 minutes". That fits the frontend sitting at 5 pods from about 22:42, and it cleared once the autoscaler scaled down after the test.
- **The 5,511 "failed" requests.** All of them are length mismatches, and the connect, receive, exception and non-2xx counts are zero. ApacheBench compares each response size to the first one. The earlier 3-minute test on the same page had no mismatches, and the release changed the page text. At about 60 requests per second, 5,511 requests is about 90 seconds of traffic, which fits the rollout landing near the end of the test. I tore the cluster down before checking the page sizes, so this is the likely cause, not a confirmed one.
- **Alerts I didn't write.** Slack also received built-in alerts from kube-prometheus-stack. `KubeSchedulerDown` and `KubeControllerManagerDown` fired because AWS runs those parts of EKS and Prometheus can't see them, so they're noise here. `KubeCPUOvercommit` was a real warning: my two nodes were over-committed by 0.34 CPU, so the cluster couldn't survive losing one.
- **Slack setup.** I first saved the webhook secret with placeholder text. Prometheus's own `AlertmanagerFailedToSendAlerts` rule noticed (about 60% of notifications failing), but that alert couldn't be delivered until the webhook worked, so it only reached Slack at 21:24, right after I recreated the secret with the real URL. It cleared by 21:44.
- **Load generator.** The demo's own load generator was running during the tests, so baseline CPU was already about 15 to 20%. The test hits only the home page.
- **Cost.** The billing page showed $6.32 month-to-date for 1 to 27 Nov, against $0.46 for the whole of October. Billing lags, so the final number may be slightly higher.

Not measured: whether there were any errors during the bad release (I sent no traffic), and the page sizes behind the 5,511 length mismatches.
