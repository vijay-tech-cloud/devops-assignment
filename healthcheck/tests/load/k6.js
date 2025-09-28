import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 200 },
    { duration: '60s', target: 500 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<300'],
  },
};

export default function () {
  const base = __ENV.BASE;
  const res = http.post(`${base}/trade/place`, JSON.stringify({ side: 'UP', amount: 1 }), { headers: { 'Content-Type': 'application/json' } });
  check(res, { '200': (r) => r.status === 200 });
  sleep(1);
}
