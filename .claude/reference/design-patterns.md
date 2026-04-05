---
description: Design patterns reference — GoF, architectural, distributed/cloud, concurrency, data, frontend, and AI/LLM patterns with intent and when to use/avoid
---

# Design Patterns Reference

## GoF — Creational
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Singleton** | One instance, global access | Shared resource (logger, config) | Need testability — use DI instead |
| **Factory Method** | Subclass decides which object to create | Object type varies by context | Simple creation — just use `new` |
| **Abstract Factory** | Family of related objects without specifying concrete classes | Multiple product families (UI themes, DB drivers) | Only one product variant |
| **Builder** | Step-by-step construction of complex objects | Many optional params, fluent config | Simple objects |
| **Prototype** | Clone existing objects | Expensive init; need variations of a base | Objects are simple to construct |

## GoF — Structural
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Adapter** | Bridge incompatible interfaces | Integrating third-party or legacy code | Interfaces are already compatible |
| **Bridge** | Separate abstraction from implementation | Multiple dimensions of variation | Only one varies |
| **Composite** | Tree structure of objects treated uniformly | File system, UI components, org charts | Hierarchy is fixed and simple |
| **Decorator** | Add behavior without subclassing | Wrapping (logging, caching, auth) | Composition of many decorators gets complex |
| **Facade** | Simplified interface to a complex subsystem | Reducing coupling to complex APIs | Already simple API |
| **Flyweight** | Share common state across many fine-grained objects | Millions of similar objects (chars, particles) | Objects have unique state |
| **Proxy** | Surrogate that controls access | Lazy load, access control, remote calls | Direct access is fine |

## GoF — Behavioral
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Chain of Responsibility** | Pass request along handler chain | Middleware, request pipelines | Chain is always the same length/shape |
| **Command** | Encapsulate operation as object | Undo/redo, queuing, audit log | Simple direct calls suffice |
| **Iterator** | Sequential access without exposing internals | Custom collections | Language provides native iteration |
| **Mediator** | Centralize object communication | Many objects communicating — reduces coupling | Few objects, direct communication is clearer |
| **Memento** | Capture/restore object state | Undo, snapshots | State is cheap to recompute |
| **Observer** | Notify dependents of state changes | Event-driven systems, UI bindings | Tight coupling is acceptable; too many observers = debugging hell |
| **State** | Object behavior changes with state | Complex state machines | Few states with simple transitions |
| **Strategy** | Swap algorithms at runtime | Pluggable behavior (sort, compression, payment) | Only one algorithm ever used |
| **Template Method** | Define skeleton; subclasses fill in steps | Shared algorithm structure with variation points | Prefer composition — inheritance is inflexible |
| **Visitor** | Add operations to object hierarchy without modifying | Adding ops to stable class hierarchy | Hierarchy changes frequently |
| **Interpreter** | Grammar for a language | DSLs, expression evaluators | Use parser library for complex grammars |

## Architectural
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Layered** | Strict separation: UI → Service → Domain → Persistence | Standard CRUD apps | Performance-critical paths (cross-layer overhead) |
| **Hexagonal (Ports & Adapters)** | Domain at center; infrastructure plugged in via ports | Domain logic must be infra-agnostic and testable | Small scripts/simple CRUD |
| **Clean Architecture** | Dependency rule: outer layers depend on inner | Long-lived, complex domain logic | Over-engineering for small projects |
| **CQRS** | Separate read and write models | Different scaling needs for reads/writes; complex query requirements | Simple apps where reads = writes |
| **Event Sourcing** | Store events, derive state | Audit trail required; temporal queries needed | Simple CRUD; state reconstruction is expensive |

## Distributed & Cloud
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Saga** | Distributed transaction via choreography or orchestration | Multi-service business transactions | Single service, local transactions work |
| **Outbox** | Reliably publish events alongside DB writes | Dual write problem (DB + message broker) | Already using event sourcing |
| **Circuit Breaker** | Stop calling failing service temporarily | External dependencies that fail unpredictably | Internal calls with low failure rates |
| **Bulkhead** | Isolate failures to prevent cascade | Critical vs. non-critical workloads | Homogeneous workloads |
| **Retry + Backoff** | Retry transient failures with delay | Network calls, rate limits | Non-idempotent operations without deduplication |
| **BFF (Backend for Frontend)** | API layer shaped per client type | Mobile vs. web need different responses | One client type, or generic API is fine |
| **Sidecar** | Attach infrastructure concerns (logging, proxy) to a pod | Cross-cutting concerns in containers | Monoliths; small deployments |
| **Strangler Fig** | Incrementally replace legacy system | Migrating monolith to microservices | Greenfield; full rewrite is feasible |
| **API Gateway** | Single entry point for routing, auth, rate limiting | Microservices — clients shouldn't know topology | Single service |
| **Service Mesh** | Infra layer for service-to-service communication | Observability, mTLS, retries at scale | Small # of services; adds operational complexity |

## Concurrency
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Actor Model** | Isolated actors communicate via messages | Highly concurrent systems, no shared state | Low-concurrency; overhead not justified |
| **Thread Pool** | Reuse threads for task execution | Many short-lived tasks | Long-running tasks (block pool) |
| **Reactor** | Single-threaded event loop dispatches handlers | I/O-bound, high-concurrency (Node.js, Netty) | CPU-bound work |
| **Scheduler** | Control task execution timing/priority | Rate limiting, delayed jobs | Real-time constraints |

## Functional
| Pattern | Intent | Use when |
|---------|--------|----------|
| **Functor** | Apply function to wrapped value (`map`) | Transforming values inside context (Optional, List) |
| **Monad** | Chain operations on wrapped values (`flatMap`) | Sequential operations that may fail or have context |
| **Lens** | Composable getter/setter for nested data | Immutable deep updates |
| **ADT (Algebraic Data Types)** | Types that represent all valid states | Making illegal states unrepresentable |
| **Partial Application / Currying** | Fix some args, return new function | Building specialized functions from general ones |

## Data
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Repository** | Abstract data access behind interface | Domain code must not know about persistence | Simple scripts; adds indirection overhead |
| **Unit of Work** | Track changes; flush in one transaction | Multiple related writes must be atomic | Single writes |
| **Data Mapper** | Map between domain objects and DB rows | Domain model ≠ DB schema | Schema mirrors domain (Active Record is simpler) |
| **Active Record** | Object wraps DB row + domain logic | Simple CRUD; schema = domain | Complex domain logic (bleeds concerns) |
| **Specification** | Encapsulate business rule as composable predicate | Reusable query/validation logic | One-off filters |

## Frontend
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **Compound Component** | Components share implicit state | Complex UI kits (tabs, accordion) | Simple components |
| **Container/Presenter** | Separate data-fetching from rendering | Testing UI without data layer | Trivial components |
| **Flux/Redux** | Unidirectional data flow via actions/reducers | Complex shared state | Local component state is enough |
| **Islands Architecture** | Hydrate only interactive parts | Mostly-static pages with some interactivity | Fully interactive SPAs |
| **Render Props / HOC** | Share behavior between components | Cross-cutting UI concerns | Hooks (prefer hooks in modern React) |

## AI / LLM (2024–2025)
| Pattern | Intent | Use when | Avoid when |
|---------|--------|----------|------------|
| **RAG** | Retrieve context before generating | Domain-specific knowledge, up-to-date facts | Model already knows the domain |
| **Agentic Loop** | LLM iterates: observe → think → act → observe | Multi-step autonomous tasks | Single-turn Q&A |
| **Router/Orchestrator** | Route prompts to specialized models/agents | Different tasks need different models | Single-model system |
| **Chain-of-Thought** | Prompt model to reason step-by-step | Complex reasoning, math, multi-step logic | Simple retrieval tasks |
| **Structured Output** | Constrain output to schema (JSON, XML) | Downstream parsing required | Free-form responses |
| **Prompt Versioning** | Version and A/B test prompts like code | Production LLM systems | Prototype/exploration |
| **Fallback Models** | Use cheaper model first, fallback on failure | Cost optimization with reliability | Latency-sensitive paths |
| **LLM as Validator** | Use LLM to verify its own or another's output | Quality gates in pipelines | Adds latency; use rule-based checks if possible |
