---
description: "Generate API test cases and runnable test code from an OpenAPI (Swagger) specification, covering happy paths, response schema validation, input validation and boundaries, auth, and error responses. Use when asked to create API tests, contract tests, or a test suite from an OpenAPI/Swagger spec (YAML or JSON)."
argument-hint: "<OpenAPI spec file or URL> [operations/tags] [framework]"
agent: agent
---

<!-- Generated from .claude/skills/api-test-generator/SKILL.md by scripts/sync-prompts.sh. Edit the source and re-run the script. -->

# API Test Generator

Derive a systematic test matrix from an OpenAPI spec and turn it into runnable, independent tests. Spec gaps found along the way are reported as findings.

## Inputs

| Input | Required | Notes |
|---|---|---|
| OpenAPI spec | Yes | OpenAPI 3.x (preferred) or Swagger 2.0; a file path, URL, or pasted YAML/JSON. In a workspace, read the file directly. |
| Scope | No | Operation IDs, paths, or tags. Defaults to every operation. |
| Framework | No | Defaults to **Playwright Test (TypeScript)** with `APIRequestContext`. Alternatives: pytest + requests, REST Assured (Java), Jest + supertest, a Postman collection. |
| Base URL & auth | No | Environment variable names only (e.g. `API_BASE_URL`, `API_TOKEN`). Never put real secrets in code. |
| Data rules | No | Seed data, cleanup requirements, read-only environments, rate limits. |

## Instructions

1. **Load and sanity-check the spec.** Note the version, `servers`, security schemes, and global `security`. Resolve `$ref`s. Report spec errors such as broken refs, missing response schemas, or contradictory constraints.
2. **Inventory the operations**: method, path, `operationId`, auth, parameters, request body, and the documented response codes.
3. **Derive cases per operation** using this checklist:
   - **Happy path** for each documented 2xx: assert the status, key headers (`Content-Type`; `Location` on 201 if documented), and that the body validates against the response schema.
   - **Defaults & optional fields**: omitted optional fields get their documented `default`.
   - **Required fields**: omit each required field, one at a time.
   - **Types & formats**: wrong JSON type; invalid `format` (`uuid`, `email`, `date-time`, `uri`).
   - **Constraints**: `minLength`/`maxLength`, `minimum`/`maximum` (incl. `exclusive*`), `pattern`, `enum`, `minItems`/`maxItems`. Test the boundary *and* one step beyond it, on both sides.
   - **Parameters**: missing required query or path params; a non-existent ID → 404; a malformed ID.
   - **Auth**: no credentials → 401; invalid or expired token → 401; insufficient role or scope → 403 (when roles or scopes are defined).
   - **Business rules & state**: duplicates → 409; invalid state transitions; idempotency of PUT and DELETE.
   - **Collections**: pagination (first page, last page, past the end, limit bounds), sorting, filtering, empty results.
   - **Strictness**: an unknown field when `additionalProperties: false`; a wrong `Content-Type` → 415 *only if documented*.
4. **Assert only documented behaviour.** If a case's response isn't documented (for example, no 400 is defined), keep the case, but assert the status class (`4xx`), add a `TODO(spec gap)` comment, and list it under **Spec gaps**.
5. **Design the test data**:
   - Each test creates what it needs via the API.
   - Use unique values per run (UUID suffixes); never hard-code IDs.
   - Clean up in teardown when a delete operation exists.
   - Tests must not depend on each other or on their order.
6. **Write the code**:
   - One file per tag or resource; a shared context or fixture for the base URL and auth, read from environment variables.
   - Validate responses against schemas derived from `components.schemas` (Ajv + ajv-formats in TS, `jsonschema` in Python).
   - Prefix test names with the case ID; use data-driven loops for validation variants; no sleeps.
7. **Self-review.** Every operation has at least one positive and one negative case, and every documented response code is exercised or explicitly explained.

## Output format

1. `### Operation inventory`: table of Method | Path | operationId | Auth | Documented responses.
2. `### Test matrix`: table of ID | Operation | Category | Scenario | Request | Expected.
3. `### Test code`: fenced code blocks, each preceded by its file path.
4. `### Spec gaps & risks`: numbered `G1`, `G2`, … and referenced from the code.
5. `### How to run`: dependencies, environment variables, command.

## Example

**Input**

```yaml
openapi: 3.0.3
info: { title: Tasks API, version: 1.0.0 }
servers: [{ url: https://api.tasks.example/v1 }]
security: [{ bearer: [] }]
components:
  securitySchemes:
    bearer: { type: http, scheme: bearer }
  schemas:
    NewTask:
      type: object
      required: [title]
      properties:
        title: { type: string, minLength: 1, maxLength: 100 }
        priority: { type: string, enum: [low, medium, high], default: medium }
    Task:
      allOf:
        - $ref: '#/components/schemas/NewTask'
        - type: object
          required: [id, createdAt]
          properties:
            id: { type: string, format: uuid }
            createdAt: { type: string, format: date-time }
paths:
  /tasks:
    post:
      operationId: createTask
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/NewTask' }
      responses:
        '201': { description: Created, content: { application/json: { schema: { $ref: '#/components/schemas/Task' } } } }
        '400': { description: Validation error }
        '401': { description: Unauthorized }
  /tasks/{id}:
    get:
      operationId: getTask
      parameters:
        - { name: id, in: path, required: true, schema: { type: string, format: uuid } }
      responses:
        '200': { description: OK, content: { application/json: { schema: { $ref: '#/components/schemas/Task' } } } }
        '401': { description: Unauthorized }
        '404': { description: Not found }
```

**Output**

### Operation inventory
| Method | Path | operationId | Auth | Documented responses |
|---|---|---|---|---|
| POST | /tasks | createTask | Bearer | 201, 400, 401 |
| GET | /tasks/{id} | getTask | Bearer | 200, 401, 404 |

### Test matrix
| ID | Operation | Category | Scenario | Request | Expected |
|---|---|---|---|---|---|
| API-001 | createTask | Happy path | All fields | `{title, priority: "high"}` | 201; body matches `Task`; echoes input |
| API-002 | createTask | Default | Priority omitted | `{title}` | 201; `priority` = `"medium"` |
| API-003 | createTask | Boundary | Title length 1 | `{title: "x"}` | 201 |
| API-004 | createTask | Boundary | Title length 100 | 100 × `"x"` | 201 |
| API-005 | createTask | Boundary | Title length 101 | 101 × `"x"` | 400 |
| API-006 | createTask | Required | Title missing | `{priority: "low"}` | 400 |
| API-007 | createTask | Boundary | Empty title | `{title: ""}` | 400 |
| API-008 | createTask | Enum | Priority not in enum | `{title, priority: "urgent"}` | 400 |
| API-009 | createTask | Type | Title is a number | `{title: 123}` | 400 |
| API-010 | createTask | Auth | No token | valid body, no `Authorization` | 401 |
| API-011 | createTask | Auth | Invalid token | `Bearer invalid` | 401 |
| API-012 | getTask | Happy path | Existing task | id from a created task | 200; body matches `Task` and equals the created task |
| API-013 | getTask | Not found | Unknown UUID | random UUID | 404 |
| API-014 | getTask | Format | Malformed id | `not-a-uuid` | 4xx (G1) |
| API-015 | getTask | Auth | No token | id from a created task | 401 |

### Test code

`tests/api/tasks.spec.ts`
```ts
import { test, expect, request, type APIRequestContext } from '@playwright/test';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import { randomUUID } from 'node:crypto';

// Keep the trailing slash and use relative paths ('tasks'), or URL resolution drops the /v1 prefix.
const BASE_URL = process.env.API_BASE_URL ?? 'https://api.tasks.example/v1/';
const TOKEN = process.env.API_TOKEN ?? '';

// Flattened from components.schemas.Task (allOf NewTask + id/createdAt).
const ajv = new Ajv({ allErrors: true });
addFormats(ajv);
const validateTask = ajv.compile({
  type: 'object',
  required: ['id', 'title', 'createdAt'],
  properties: {
    id: { type: 'string', format: 'uuid' },
    title: { type: 'string', minLength: 1, maxLength: 100 },
    priority: { type: 'string', enum: ['low', 'medium', 'high'] },
    createdAt: { type: 'string', format: 'date-time' },
  },
});

const uniqueTitle = () => `qa-${randomUUID()}`;

let api: APIRequestContext;
let anon: APIRequestContext;

test.beforeAll(async () => {
  api = await request.newContext({ baseURL: BASE_URL, extraHTTPHeaders: { Authorization: `Bearer ${TOKEN}` } });
  anon = await request.newContext({ baseURL: BASE_URL });
});

test.afterAll(async () => {
  await api.dispose();
  await anon.dispose();
});

test.describe('POST /tasks (createTask)', () => {
  test('API-001 creates a task with all fields', async () => {
    const title = uniqueTitle();
    const res = await api.post('tasks', { data: { title, priority: 'high' } });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(validateTask(body), JSON.stringify(validateTask.errors)).toBe(true);
    expect(body).toMatchObject({ title, priority: 'high' });
  });

  test('API-002 defaults priority to medium', async () => {
    const res = await api.post('tasks', { data: { title: uniqueTitle() } });
    expect(res.status()).toBe(201);
    expect((await res.json()).priority).toBe('medium');
  });

  for (const [id, title] of [['API-003', 'x'], ['API-004', 'x'.repeat(100)]] as const) {
    test(`${id} accepts a title of length ${title.length}`, async () => {
      const res = await api.post('tasks', { data: { title } });
      expect(res.status()).toBe(201);
    });
  }

  const invalidBodies = [
    { id: 'API-005', name: 'a title longer than 100', data: { title: 'x'.repeat(101) } },
    { id: 'API-006', name: 'a missing title', data: { priority: 'low' } },
    { id: 'API-007', name: 'an empty title', data: { title: '' } },
    { id: 'API-008', name: 'a priority outside the enum', data: { title: uniqueTitle(), priority: 'urgent' } },
    { id: 'API-009', name: 'a non-string title', data: { title: 123 } },
  ];
  for (const c of invalidBodies) {
    test(`${c.id} rejects ${c.name} with 400`, async () => {
      // TODO(spec gap G2): assert the error body once the 400 schema is documented.
      const res = await api.post('tasks', { data: c.data });
      expect(res.status()).toBe(400);
    });
  }

  test('API-010 rejects a missing token with 401', async () => {
    const res = await anon.post('tasks', { data: { title: uniqueTitle() } });
    expect(res.status()).toBe(401);
  });

  test('API-011 rejects an invalid token with 401', async () => {
    const res = await anon.post('tasks', {
      data: { title: uniqueTitle() },
      headers: { Authorization: 'Bearer invalid' },
    });
    expect(res.status()).toBe(401);
  });
});

test.describe('GET /tasks/{id} (getTask)', () => {
  test('API-012 returns an existing task', async () => {
    const created = await (await api.post('tasks', { data: { title: uniqueTitle() } })).json();
    const res = await api.get(`tasks/${created.id}`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(validateTask(body), JSON.stringify(validateTask.errors)).toBe(true);
    expect(body).toEqual(created);
  });

  test('API-013 returns 404 for an unknown id', async () => {
    const res = await api.get(`tasks/${randomUUID()}`);
    expect(res.status()).toBe(404);
  });

  test('API-014 rejects a malformed id', async () => {
    // TODO(spec gap G1): the spec documents neither 400 nor 404 for a non-UUID id.
    const res = await api.get('tasks/not-a-uuid');
    expect([400, 404]).toContain(res.status());
  });

  test('API-015 rejects a missing token with 401', async () => {
    const created = await (await api.post('tasks', { data: { title: uniqueTitle() } })).json();
    const res = await anon.get(`tasks/${created.id}`);
    expect(res.status()).toBe(401);
  });
});
```

### Spec gaps & risks
- **G1.** The response to a malformed `id` (not a UUID) on `getTask` is undocumented: 400 or 404?
- **G2.** The `400` response has no schema, so tests can't assert the error format or the offending field.
- **G3.** No roles or scopes are defined, so authorisation (403) can't be covered. Confirm whether any user can read any task, which would be a potential access-control risk.
- **G4.** There is no `DELETE /tasks/{id}`, so tests leave data behind. Run them against a disposable environment, or add a cleanup endpoint.
- **G5.** The `201` response doesn't document a `Location` header.

### How to run
```bash
npm i -D @playwright/test ajv ajv-formats
API_BASE_URL=https://api.tasks.example/v1/ API_TOKEN=<token> npx playwright test tests/api
```
