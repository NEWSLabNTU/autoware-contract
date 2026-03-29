# Roadmap

Work items for enriching Autoware contract manifests with new format features.

See [../status.md](../status.md) for per-launch-file implementation status.

## Phases

| Phase | Name | Description | Status |
|-------|------|-------------|--------|
| 1 | [Service Contracts](1-service-contracts.md) | Add `max_response_ms` to srv/cli endpoints | On hold (need traceable sources) |
| 2 | [Args & Substitutions](2-args-substitutions.md) | Add `args:` + `$(var ...)` matching launch file context | Complete |
| 3 | [Conditions](3-conditions.md) | Add `if:`/`unless:` for conditional nodes/topics | Complete (control only — others are plugin-level, see Note 7) |
| 4 | [End-to-End Validation](4-end-to-end-validation.md) | Run `play_launch check` against real Autoware launch | Not started |
| 5 | [Service Wiring](5-service-wiring.md) | Add scope-level `services:` entries | Complete (cross-scope documented as gap) |
| 6 | [Optional Refs](6-optional-refs.md) | Add `?` suffix on conditional endpoint refs | Complete |

## Phase Order

```
1 (service contracts) ──────────────────┐
                                        │
2 (args) ──→ 3 (conditions) ────────────┤
                                        │
4 (end-to-end validation) ──────────────┤
                                        │
5 (service wiring) ─────────────────────┘
```

1 is independent. 2 must precede 3. 4 can run after any phase to validate.
5 is independent but benefits from 1 (service contracts on endpoints first).
