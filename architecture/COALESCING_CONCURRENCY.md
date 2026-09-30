we have the following problems:

- the sync operation that pulls and pushes pending mutations, it can be triggered by many triggers:
  - timer
  - network available
  - app resumed from background
    which means if the network becomes available and at that same time a tick awakes then the two of them will call perfomSync of syncEngine at the same time we will have two calls for the same task twice which is unecessary. to enforce only one call at a time we use coalescing.
- the other problem is should we be able to call a performSync when a refreshRequest is running and what can go wrong?
