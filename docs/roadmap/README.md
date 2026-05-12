# Roadmap

Work items for enriching Autoware contract manifests with new format features.

See [../status.md](../status.md) for per-launch-file implementation status.

## Phases

| Phase | Name | Description | Status |
|-------|------|-------------|--------|
| 1 | [Service Contracts](1-service-contracts.md) | Add `max_response_ms` to srv/cli endpoints | On hold (need traceable sources) |
| 2 | [Args & Substitutions](2-args-substitutions.md) | Add `args:` + `$(var ...)` matching launch file context | Complete |
| 3 | [Conditions](3-conditions.md) | Add `if:`/`unless:` for conditional nodes/topics | Complete (control only — others are plugin-level, see Note 7) |
| 4 | [End-to-End Validation](4-end-to-end-validation.md) | Run `play_launch check` against real Autoware launch | Complete (0 errors, 149 warnings) |
| 5 | [Service Wiring](5-service-wiring.md) | Add scope-level `services:` entries | Complete (cross-scope documented as gap) |
| 6 | [Optional Refs](6-optional-refs.md) | Add `?` suffix on conditional endpoint refs | Complete |
| 7 | [Format v2 Adoption](7-format-v2-adoption.md) | Adopt unified interface, arg types, satisfiability | Blocked on play_launch Phase 33 |
| 8 | [Intermediate Manifests](8-intermediate-manifests.md) | Cover orchestrator launch files | Complete |
| 9 | [Format Up-to-Date Migration](9-format-up-to-date-migration.md) | Migrate to current spec (post-Phase 35); add lifecycle, transport, endpoint qos | Complete (9.1–9.8) — 9.9/9.13 no-op; 9.10–9.12 deferred to runtime/source review |
| 10 | [Topic Promotion](10-topic-promotion.md) | Promote `external_topics:` orphans into first-class `topics:` declarations with QoS / annotate every observed FQN as half-external | Complete (rounds 1–11 done; 0 `external: both` remain — all 815 entries now half-external, 163 promoted to leaf `topics:`) |

## Phase Order

```
1 (service contracts) ──────────────────┐
                                        │
2 (args) ──→ 3 (conditions) ────────────┤
                                        │
4 (end-to-end validation) ──────────────┤
                                        │
5 (service wiring) ─────────────────────┘

9 (format migration) — reopens 1, 4, 7; required before further authoring
```

1 is independent. 2 must precede 3. 4 can run after any phase to validate.
5 is independent but benefits from 1 (service contracts on endpoints first).
9 supersedes the format pieces of phases 5–8 by aligning with the
post-Phase-35 play_launch spec; later phases (e.g. reopened 1, 4) build
on 9.
