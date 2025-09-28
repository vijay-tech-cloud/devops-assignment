import assert from 'node:assert/strict';
import http from 'node:http';
import { once } from 'node:events';
import { spawn } from 'node:child_process';

const srv = spawn('node', ['server.js'], { cwd: './app', env: { PORT: '9090' }});
await once(srv.stdout, 'data');

const res = await fetch('http://127.0.0.1:9090/health');
assert.equal(res.status, 200);
assert.equal((await res.json()).ok, true);

srv.kill();
