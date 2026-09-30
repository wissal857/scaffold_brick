we will have beside the business entities tables, syncMetadata table, syncOperation table and queryMetadata for queries that return more than one result.

Refresh can be triggered on :

- repository findById : refreshes only that entity
- repository findAll : refreshes that query by looking for its hash in the queryMetadata table queryKey
- timer or app resume from background: refresh by scope

## Tables

# Business entities

These tables will have the following metadata added to them:

- version: which will be sent by the server
- createdAt
- updatedAt
- nextRefreshAt
- retryCount
- nextRetryAt
- lastRefreshError

# QueryMetadata

this table will be used when fetching more than one entity record in order to decide when to refresh the query result and track its status with retry logic, the metadta will contain the following fields:

- queryKey : this will be the hash of the canonical version of the query
- canonicalQuery: this will be stored for logging purposes in order to keep the query understandable. example : { "entity": "users", "page": 1, "limit": 10, "sort": "name"}
- etag
- nextRefreshAt
- retryCount
- nextRetryAt
- lastRefreshError
- createdAt
- updatedAt

## Sync engine

syncEngine.start()

- initialize components
- start mutation processing
- start refresh scheduling
- schedule background work

syncEngine.pause()

- stop scheduling new refreshes
- stop polling/timers
- prevent new sync cycles
- optionally allow current operations to finish

Cases where the sync engine can pause:

- user logs out
- Database is being replaced/recreated
