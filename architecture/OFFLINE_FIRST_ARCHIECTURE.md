# Offline-First System design

## Read Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant View as View / ViewModel
    participant Repo as Repository
    participant Cache as Local Persistent Cache
    participant API as HTTP API

    User->>View: Open screen / request resource
    View->>Repo: loadResource(resourceId)
    Repo->>Cache: read(resourceId)

    alt Cache hit
        Cache-->>Repo: Cached data + stored ETag + lastSyncedAt + staleness status
        Repo-->>View: Return cached data immediately
        View-->>User: Render cached data
        alt Cached record is stale and visible
            Repo->>API: GET /resource/{id}\nIf-None-Match: <stored-etag>
        else Cached record is fresh enough
            Note over Repo,API: No immediate foreground refresh required
        end
    else Cache miss
        Cache-->>Repo: No local data
        Repo-->>View: Return loading / empty local state
        Repo->>API: GET /resource/{id}
    end

    alt 304 Not Modified
        API-->>Repo: 304 Not Modified
        Repo->>Cache: keep cached record, refresh metadata if needed
        Repo-->>View: Emit synced cached state
        View-->>User: Keep current data, clear stale/sync indicator
    else 200 OK with new representation
        API-->>Repo: 200 OK + body + ETag: <new-etag>
        Repo->>Cache: upsert(body, etag, fetchedAt)
        Cache-->>Repo: Persist success
        Repo-->>View: Emit fresh data from server
        View-->>User: Update screen with latest data
    else Network failure / timeout
        API--x Repo: Connectivity or timeout error
        Repo-->>View: Emit cached data with offline/stale status
        View-->>User: Show last known data + offline indicator
    else 404 / unrecoverable server error
        API-->>Repo: Error response
        Repo-->>View: Emit domain failure + fallback state
        View-->>User: Show recoverable error UI
    end
```

## Write Flow

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant View as View / ViewModel
    participant Repo as Repository
    participant Cache as Local Persistent Cache
    participant Queue as Sync Queue
    participant API as HTTP API

    User->>View: Edit data and tap save
    View->>Repo: saveResource(updateCommand)
    Repo->>Cache: read current local record
    Cache-->>Repo: Current data + stored ETag + sync metadata

    Repo->>Cache: apply optimistic update\nmark record pendingSync
    Cache-->>Repo: Persist success
    Repo-->>View: Emit updated local state immediately
    View-->>User: Show saved locally / syncing state

    alt Network available
        Repo->>API: PUT/PATCH /resource/{id}\nIf-Match: <stored-etag>

        alt 200/201 OK
            API-->>Repo: Success + canonical body + ETag: <new-etag>
            Repo->>Cache: replace optimistic data\nclear pendingSync\nstore new ETag
            Cache-->>Repo: Persist success
            Repo-->>View: Emit synced state
            View-->>User: Show sync complete
        else 412 Precondition Failed
            API-->>Repo: Conflict, ETag mismatch
            Repo->>API: GET /resource/{id}
            API-->>Repo: Latest server body + ETag
            Repo->>Cache: store server version\nmark conflict state
            Repo-->>View: Emit conflict state with local/server versions
            View-->>User: Show conflict resolution UI
        else Transient failure
            API--x Repo: Timeout / temporary server error
            Repo->>Queue: enqueue idempotent retry job\nwith payload + ETag + retry policy
            Repo-->>View: Keep optimistic state + pendingSync
            View-->>User: Show queued for retry / offline state
        end
    else Network unavailable
        Repo->>Queue: enqueue write job\nwith payload + ETag + idempotency key
        Repo-->>View: Keep optimistic state + pendingSync
        View-->>User: Show saved offline / pending sync
    end

    loop Background sync when connectivity returns
        Queue->>Repo: dequeue pending write
        Repo->>API: Retry PUT/PATCH with\nIf-Match + Idempotency-Key

        alt Retry success
            API-->>Repo: Success + body + ETag
            Repo->>Cache: commit server-confirmed state\nclear pendingSync
            Repo-->>View: Emit synced state
        else Retry conflict
            API-->>Repo: 412 Precondition Failed
            Repo->>Cache: keep pending/conflict marker
            Repo-->>View: Emit conflict state
        else Retry still failing
            API--x Repo: Transient failure
            Repo->>Queue: reschedule with backoff
        end
    end
```

## Sync Engine Flow

```mermaid
sequenceDiagram
    autonumber
    participant Trigger as Connectivity / Scheduler Trigger
    participant Engine as Sync Engine
    participant Queue as Sync Queue
    participant Repo as Repository
    participant Cache as Local Persistent Cache
    participant API as HTTP API
    participant Monitor as Logging / Monitoring

    Trigger->>Engine: connectivity restored / periodic wakeup
    Engine->>Queue: load due pending operations
    Queue-->>Engine: ordered jobs ready for sync

    loop For each queued operation
        Engine->>Repo: sync(operation)
        Repo->>Cache: read current local record + metadata
        Cache-->>Repo: local data + ETag + sync status

        alt Safe to retry
            Repo->>API: request with If-Match / If-None-Match\nIdempotency-Key when applicable

            alt Success
                API-->>Repo: 200/201/204 + body? + ETag
                Repo->>Cache: persist canonical server state\nclear pendingSync\nupdate lastSyncedAt
                Repo->>Queue: remove completed job
                Repo-->>Engine: sync success
                Engine->>Monitor: record success metric / trace
            else 304 Not Modified
                API-->>Repo: 304 Not Modified
                Repo->>Cache: refresh sync metadata only
                Repo->>Queue: remove completed read-refresh job
                Repo-->>Engine: no-op success
                Engine->>Monitor: record no-change result
            else 412 Precondition Failed
                API-->>Repo: conflict detected
                Repo->>API: fetch latest server version
                API-->>Repo: latest body + ETag
                Repo->>Cache: store server snapshot\nmark conflict state\npreserve local pending change
                Repo->>Queue: pause or reclassify job as conflict
                Repo-->>Engine: conflict result
                Engine->>Monitor: record conflict event
            else transient failure
                API--x Repo: timeout / temporary network / 5xx
                Repo->>Queue: reschedule with exponential backoff
                Repo-->>Engine: retry scheduled
                Engine->>Monitor: record retryable failure
            else permanent failure
                API-->>Repo: unrecoverable validation / auth / domain error
                Repo->>Cache: mark failed or degraded state
                Repo->>Queue: dead-letter or require manual resolution
                Repo-->>Engine: terminal failure
                Engine->>Monitor: record alertable failure
            end
        else Not safe to retry
            Repo->>Queue: keep job blocked pending user resolution
            Repo-->>Engine: unsafe retry skipped
            Engine->>Monitor: record skipped unsafe retry
        end
    end

    Engine->>Queue: update engine checkpoint / next wakeup
    Engine->>Monitor: publish sync summary
```

## Sync Operation State Diagram

```mermaid
stateDiagram-v2
    [*] --> pending

    pending --> in_progress: worker picks job
    pending --> cancelled: user/system cancels job

    in_progress --> completed: sync succeeds
    in_progress --> failed_retryable: timeout / 5xx / temporary network error
    in_progress --> failed_fatal: unrecoverable validation / auth / domain error
    in_progress --> conflict: ETag mismatch / server version conflict\\nresolve with last write wins when local != remote version
    in_progress --> cancelled: cancellation requested

    failed_retryable --> pending: retry scheduled / backoff elapsed
    failed_retryable --> cancelled: retry abandoned

    conflict --> pending: conflict resolved and requeued
    conflict --> cancelled: user discards local change
    conflict --> failed_fatal: conflict cannot be resolved automatically

    completed --> [*]
    failed_fatal --> [*]
    cancelled --> [*]
```

Note: a mutation may be committed locally and shown as an immediate optimistic success before remote sync begins. That does not eliminate cancelability. As long as the queued job remains in `pending`, the system can still offer an undo window. Example: after the user archives an item, the app updates the local database immediately, shows a snackbar such as `Item archived. Undo?`, and delays sync for a few seconds. If the user taps `Undo` before the job moves to `in_progress`, the app reverts the local change and marks the queued job as `cancelled` or removes it entirely.

Note: under a last-write-wins policy, a `412 Precondition Failed` should not normally cause the next retry to drop the `If-Match` header. The safer pattern is to fetch the latest server version, decide that the local change should win, then requeue the operation with the new current `ETag` and retry again with `If-Match`. Removing `If-Match` entirely would turn the retry into an unconditional overwrite and can clobber newer remote changes.

## Server-Client request response flow

```mermaid
sequenceDiagram
    autonumber
    participant Client
    participant Cache as Server Cache
    participant Server as Backend Server

    Note over Client, Server: First Request (Cold Cache)
    Client->>Cache: GET /resource
    Cache->>Server: GET /resource
    Server-->>Cache: 200 OK (Data + ETag: "v1")
    Cache-->>Client: 200 OK (Data + ETag: "v1")
    Note right of Client: Client stores ETag "v1" locally

    Note over Client, Server: Second Request (Conditional GET)
    Client->>Cache: GET /resource (If-None-Match: "v1")

    alt ETag Matches (Cache Hit/Valid)
        Cache-->>Client: 304 Not Modified (No Body)
        Note left of Client: Client uses local copy
    else ETag Mismatches or Expired (Cache Miss/Stale)
        Cache->>Server: GET /resource (If-None-Match: "v1")
        Server->>Server: Compare ETag "v1" with current version "v2"
        Server-->>Cache: 200 OK (New Data + ETag: "v2")
        Cache->>Cache: Update Cache with "v2"
        Cache-->>Client: 200 OK (New Data + ETag: "v2")
    end
```

## Background Refresh System Design

### Delta sync design goals

- refresh collections efficiently without issuing one request per record
- fetch only changes since the last successful sync checkpoint
- reduce network, battery, and backend load compared with per-record polling
- preserve local readability during outages or partial refresh failures
- keep delta checkpoints version-aware and safe to reset when invalidated

### Main components

- `refresh_scheduler`: wakes on timer, app foreground, connectivity restore, or explicit user action
- `delta_selector`: identifies collections or scopes due for refresh instead of individual rows
- `delta_checkpoint_store`: stores per-scope sync token, cursor, high-water mark, or last successful server version
- `delta_repository`: issues collection-level delta requests such as `GET /items/delta?since=<token>`
- `delta_apply_engine`: applies inserts, updates, deletes, and tombstones transactionally to the local database
- `delta_worker_pool`: processes only a bounded number of collection refreshes concurrently
- `delta_backoff_policy`: updates next refresh schedule, retry counters, and jitter after each attempt
- `delta_monitoring`: records delta sizes, latency, retry counts, invalid token events, and full-resync fallbacks

## Background Refresh Flow Using Delta Sync

```mermaid
sequenceDiagram
    autonumber
    participant Trigger as Timer / Foreground / Connectivity Trigger
    participant Scheduler as Refresh Scheduler
    participant Selector as Delta Scope Selector
    participant Checkpoint as Delta Checkpoint Store
    participant Pool as Worker Pool
    participant Repo as Delta Repository
    participant API as HTTP API
    participant Apply as Delta Apply Engine
    participant Cache as Local Persistent Cache
    participant Monitor as Logging / Monitoring

    Trigger->>Scheduler: wake refresh cycle
    Scheduler->>Selector: query due scopes where nextRefreshAt <= now
    Selector-->>Scheduler: ordered collection scopes
    Scheduler->>Pool: submit scoped delta jobs with bounded concurrency

    loop For each due scope
        Pool->>Checkpoint: load sync token / cursor / lastSyncVersion
        Checkpoint-->>Pool: current checkpoint
        Pool->>Repo: refreshScope(scope, checkpoint)
        Repo->>API: GET /scope/delta?since=<checkpoint>

        alt 200 OK with delta page
            API-->>Repo: delta payload + nextCursor? + newSyncToken + hasMore
            Repo->>Apply: apply inserts / updates / deletes / tombstones
            Apply->>Cache: transactional upsert/delete
            Cache-->>Apply: persist success
            Apply-->>Repo: delta applied
            Repo->>Checkpoint: save new token / cursor / lastRefresh metadata

            alt more pages available
                Checkpoint-->>Pool: continue same scoped job with nextCursor
            else delta complete
                Repo-->>Pool: scope refresh complete
                Pool->>Monitor: record successful delta cycle
            end
        else 304 / empty delta
            API-->>Repo: no changes or empty delta set
            Repo->>Checkpoint: update nextRefreshAt / lastAttemptAt
            Repo-->>Pool: scope unchanged
            Pool->>Monitor: record no-change result
        else invalid or expired sync token
            API-->>Repo: token invalid / reset required
            Repo->>Checkpoint: clear stale checkpoint
            Repo-->>Pool: escalate to full resync fallback
            Pool->>Monitor: record token reset event
        else transient failure
            API--x Repo: timeout / temporary network / 5xx / 429
            Repo->>Checkpoint: keep existing checkpoint\nbackoff nextRefreshAt
            Repo-->>Pool: retryable failure
            Pool->>Monitor: record retryable failure
        else permanent failure
            API-->>Repo: unrecoverable request / auth / domain error
            Repo->>Checkpoint: mark scope degraded or blocked
            Repo-->>Pool: terminal failure
            Pool->>Monitor: record terminal failure
        end
    end

    Scheduler->>Monitor: publish delta refresh summary
```

## Delta Refresh State Diagram

```mermaid
stateDiagram-v2
    [*] --> idle

    idle --> selecting: scheduler wakes
    selecting --> loading_checkpoint: due scope selected
    selecting --> idle: no due scopes

    loading_checkpoint --> requesting_delta: checkpoint loaded
    requesting_delta --> applying_delta: delta response received
    applying_delta --> requesting_delta: nextCursor exists
    applying_delta --> completed: delta applied and no more pages

    requesting_delta --> unchanged: empty delta / no changes
    requesting_delta --> full_resync_required: token invalid or expired
    requesting_delta --> retryable_failure: timeout / 5xx / 429
    requesting_delta --> terminal_failure: unrecoverable request / auth error

    unchanged --> completed
    retryable_failure --> idle: backoff scheduled
    terminal_failure --> idle: blocked until manual or policy recovery
    full_resync_required --> idle: full snapshot job scheduled
    completed --> idle
```

### Delta-specific metadata

- `syncScopeId`: collection, query, tenant, or feature scope being refreshed
- `syncToken`: opaque server-issued token representing the last successful delta checkpoint
- `deltaCursor`: pagination cursor for multi-page delta responses
- `lastSyncVersion`: optional monotonic server version if the API uses versions instead of opaque tokens
- `lastFullResyncAt`: timestamp of the most recent full snapshot rebuild
- `requiresFullResync`: flag set when the delta token is invalidated
- `deltaPageSize`: requested or negotiated page size for delta responses
- `tombstoneRetentionUntil`: time until delete tombstones must be retained locally for sync safety

## Companion Notes

### Suggested local cache record shape

- `id`: stable resource identifier
- `data`: latest locally stored canonical or optimistic payload
- `etag`: last known server `ETag` for conditional read/write requests
- `lastSyncedAt`: timestamp of the last confirmed successful sync with the server
- `lastFetchedAt`: timestamp of the last fetch attempt that returned usable data
- `syncStatus`: enum such as `synced`, `pending_sync`, `conflict`, `stale`, `failed`
- `version`: optional local monotonic version for merge/conflict support
- `idempotencyKey`: optional key attached to queued writes that may be retried safely

### Suggested sync metadata for queued writes

- `operationId`: unique identifier for the queued sync job
- `resourceId`: target resource identifier
- `operationType`: create, update, delete, or patch. `patch` means a partial update that sends only the changed fields, typically using HTTP `PATCH`, instead of replacing the full resource.
- `payload`: serialized write command to replay
- `etagAtEditTime`: `ETag` value that was current when the user made the change
- `retryCount`: number of attempts already made
- `nextRetryAt`: scheduled time for the next retry attempt
- `lastErrorCode`: latest mapped failure code
- `lastErrorMessage`: latest human-readable diagnostic message
- `createdAt`: when the queued operation was first stored
- `updatedAt`: when the queued operation was last retried or mutated
- `nextRefreshAt`: scheduled time for the next background refresh attempt
- `refreshPriority`: optional priority used by the background refresh scheduler
- `refreshGroupKey`: optional deduplication or batching key for collection refresh
- `syncToken`: last successful delta checkpoint token for a collection or scope
- `deltaCursor`: current cursor when a delta refresh spans multiple pages
- `requiresFullResync`: whether the next refresh must fall back to a full snapshot

### Practical notes

- Reads should prefer cache-first rendering. If the cached record is stale and needed now by a visible foreground read, return it immediately and trigger an immediate refresh using `If-None-Match` rather than waiting only for the background delta scheduler.
- Writes should update local state first, then sync with `If-Match` when an `ETag` is available.
- A robust mutation workflow is usually: commit to the local database first, create a sync operation record, then let the sync engine send it immediately if network is available and no higher-priority queued work blocks it; otherwise keep it in the queue as `pending`.
- Retry only idempotent or explicitly protected writes, ideally with an `Idempotency-Key`.
- Retryable failures should typically use exponential backoff, for example `delay = baseDelay * 2^retryCount`, while enforcing both a `maxDelay` cap and a `maxRetries` limit so retries do not grow forever or loop indefinitely.
- Add jitter to the computed retry delay so many devices do not retry in lockstep. This spreads load across time, reduces thundering-herd spikes, and gives the backend a better chance to recover under outage conditions.
- When the API supports delta sync, background refresh should prefer collection- or scope-level delta requests over per-record polling. The scheduler should select due scopes, load their `syncToken`, process only a bounded number concurrently, and update checkpoints transactionally after each successful delta application.
- If a delta token becomes invalid, the system should not guess a new checkpoint. It should clear the token, mark the scope as requiring full resync, and schedule a snapshot rebuild explicitly.
- Conflict states should preserve both the local pending change and the latest server snapshot for resolution.

## Eviction Policies

### Common policies

- `TTL`: evict data after a fixed age
- `LRU`: evict least recently used records first
- `LFU`: evict least frequently used records first
- `FIFO`: evict oldest inserted records first
- `size-based`: evict when storage usage exceeds a byte threshold
- `count-based`: keep only the newest or most relevant N records
- `staleness-based`: evict data whose freshness window expired and is cheap to refetch
- `priority-tier`: evict low-value or non-critical data before important data
- `cost-aware`: keep expensive-to-download or expensive-to-recompute data longer
- `sync-state-aware`: never evict pending, conflicted, or unsynced records
- `scope-based`: evict by workspace, user, tenant, feature, or collection
- `event-driven`: evict on logout, account switch, permission loss, or feature disablement
- `version-based`: evict data that is incompatible with a new schema or content version
- `tombstone-retention`: prune delete tombstones after the sync safety window expires
- `manual`: let the user clear cached or offline data explicitly

### Recommended offline-first rule

- Use hybrid eviction policies instead of a single global rule.
- Apply aggressive eviction only to cache-like, replaceable, or low-value data.
- Do not evict user-owned, promised-offline, pending-sync, or conflict-state data unless the product explicitly allows that loss.
- Prefer size, age, value, and sync-state based retention policies over a naive fixed row cap per table.
