# Concurrency Deeper

Sub-page of `nearly-pure-functional/SKILL.md`. Loaded on demand. No frontmatter.

Concurrency primitives FP discipline does not erase. Pure core is race-free by construction; the shell still has to coordinate. Glossary; reach in when designing a concurrent boundary.

## Vocabulary

- **Race.** Two threads / tasks read and write shared mutable state with no ordering guarantee.
- **Atomicity.** An operation appears indivisible to other observers (no partial state visible).
- **Linearizability.** Concurrent operations look as if they happened in some sequential order matching real time.
- **Happens-before.** Partial order across threads/tasks; the basis for reasoning about visibility.
- **Memory fence / barrier.** Hardware-level ordering primitive; rarely written directly in application code, but relevant for lock-free data structures.
- **Lock / mutex.** Mutual exclusion over a critical section. Cheap correctness; costly throughput.
- **Channel / queue.** Pass values between tasks; no shared memory across the boundary. Preferred shape.
- **Back-pressure.** Producer blocks or sheds when consumer cannot keep up. Bounded queue is the usual mechanism.
- **Idempotent retry.** Operation safe to repeat; required when network may double-deliver.
- **At-least-once vs exactly-once.** Network primitives are at-least-once; "exactly-once" is achieved via idempotency keys.
- **Eventual consistency.** Replicas converge; at any instant they may differ. UX must accommodate.
- **Fan-in / fan-out.** Many producers to one consumer; one producer to many consumers.
- **Structured concurrency.** Child tasks bounded by parent scope; cancellation propagates downward; no orphan tasks.
- **Cancellation token / scope.** Capability passed to cancellable work; aborts cooperatively.
- **CRDT.** Conflict-free replicated data type; merges concurrent edits deterministically.
- **Logical clock.** Lamport / vector clock; orders events without wall time.

## Patterns

- **Channels over locks.** Shape concurrency as message passing; reserve locks for tight critical sections only.
- **Bounded queues for back-pressure.** Unbounded queues hide overload until OOM.
- **Idempotency keys at the edge.** Every external call retried -> needs a key the receiver can dedupe on.
- **Pure fold per actor.** Actor body is `(state, message) -> (state', effects)`; no shared mutable state across actors.
- **Cancellation as a capability.** Long-running work takes a `CancelToken`; checks it at safe points.

## Red Flags - STOP

- Shared mutable state across threads / async tasks without a lock or a channel.
- Unbounded queue between producer and consumer.
- Retry loop without an idempotency key (will double-charge, double-send).
- Lock held across an `await` / `.await` (deadlock waiting to happen).
- Long-running task with no cancellation path.
- "Exactly-once" claim over a network primitive that is at-least-once.
- Concurrent map / set used as if linearizable when the API only guarantees per-operation atomicity.

## Reviewer Notes

When changes introduce concurrency:

1. Confirm shared state is either immutable, behind a lock, or behind a channel.
2. Confirm queues are bounded.
3. Confirm cancellation propagates from the entry point.
4. Flag any retry without an idempotency key.

## See Also

- `boundaries-deeper.md` - serialization at concurrent boundaries
- `tier-3.md` - structured concurrency in effect-typed systems
