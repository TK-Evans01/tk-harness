# Rust linter configs

Scaffold-time defaults. Copy into the project root; project-owned after.

## Files

| File                            | Purpose                                              |
|---------------------------------|------------------------------------------------------|
| `clippy.toml`                   | Clippy thresholds (cognitive complexity, etc.)       |
| `workspace-lints.toml.snippet`  | `[workspace.lints]` block for `Cargo.toml`           |
| `visibility-audit.sh`           | Advisory grep for `pub` outside `lib.rs`/`mod.rs`    |
| `example-verify.toml.snippet`   | The `[verify.rust]` block                            |

## Install

Nothing extra — `cargo clippy` ships with the toolchain.
For workspace-wide lint propagation you need rust >= 1.74.

## Run

```
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all
./visibility-audit.sh        # advisory, exits 0
```

## Tier-2 notes

- `clippy::unwrap_used`, `clippy::expect_used`, `clippy::panic` are
  **deny** in lib code; tests opt in via `#[cfg_attr(test, allow(...))]`
  at the module level, e.g.

  ```rust
  #[cfg(test)]
  #[allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]
  mod tests {
      // ...
  }
  ```

- `clippy::pedantic` is **warn**, not deny — keep signal-to-noise sane.
  Selectively bump individual pedantic lints to deny per project.
- `dbg_macro` is **deny** in non-test code.
- `print_stdout` is **warn** — fine in CLIs, noisy in libs; tighten
  per project if you ship a library crate.
- `missing_errors_doc` and `missing_panics_doc` are **warn** to nudge
  docs without blocking builds.

## What is *not* machine-checked

- "No I/O in core" — there is no clippy lint for "must not call
  `std::fs`". Rely on:
  - workspace crate split (`core` crate has no `std::fs` / `tokio` deps),
  - the reviewer pass (Step 3a) for stragglers.
- "No `Date`-equivalent in core" — same: split crates, then reviewer.
- Mutation of arguments — Rust's borrow checker handles this.

## Visibility audit

`visibility-audit.sh` greps for `pub ` outside `lib.rs`/`mod.rs` and
prints offenders. It is **advisory** (always exits 0); /verify reports
it but does not fail on it.
