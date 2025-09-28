# SLOs

- Availability: **99.9%** monthly
- p95 latency (POST /trade/place): **< 300 ms**
- Error rate: **< 1%**

Freeze prod deploys if error budget is burned. Gate promotions on k6 thresholds.
