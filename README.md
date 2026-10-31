> [!NOTE]
> **getployz/corrosion** is Ployz's build of [superfly/corrosion](https://github.com/superfly/corrosion).
> The `ployz` branch is upstream `main` plus the patches below, one commit each, rebased weekly.
> Each patch is meant to go upstream, and leaves this list once upstream has it.
> Images: `ghcr.io/getployz/corrosion:<commit date>-<sha12>`, built from `ployz/Dockerfile`.
>
> | Patch | Why | Upstream |
> |---|---|---|
> | Forget a dropped batch in the seen cache so sync can redeliver it | A batch that fails (e.g. write-permit timeout) stays in `seen`, so its partial versions never fill until restart ([getployz/ployz#3199](https://github.com/getployz/ployz/issues/3199)) | [#577](https://github.com/superfly/corrosion/issues/577), PR [#594](https://github.com/superfly/corrosion/pull/594) |
> | Add `[db] synchronous` to choose how write connections sync the WAL | With the default `NORMAL`, a power loss drops commits Corrosion already broadcast, and peers never send a node its own changes back. `full` syncs each commit before broadcast, in one sync per commit rather than one per page as an inode sync flag does ([getployz/ployz#2925](https://github.com/getployz/ployz/issues/2925)) | not offered yet |
> | Build files: `ployz/Dockerfile`, `.github/workflows/ployz-*.yml`, this note | Image publishing and the weekly rebase. The arm64 image sets `JEMALLOC_SYS_WITH_LG_PAGE=14` for 16K-page kernels | not for upstream |

# Corrosion
Gossip-based service discovery (and more) for large distributed systems.

## Why we built Corrosion

We built Corrosion specifically for service discovery across a large global network, replacing Consul’s central state database with eventually consistent state distributed across our hosts.

Our new tool needed to deliver the following:

### Fast reads and writes

Getting state (data) from a central remote source can be incredibly expensive (at least 300ms for a round-trip to something on the other side of the world), but usually takes less than 1ms from a local source.

### Fast, eventual, consistency

Many use cases can cope with eventual consistency, especially if a consistent state is attained sooner than later. Raft fell short for some use cases at Fly.io where round-trips to a centralized location are too expensive.

### Flexibility

Global state for a distributed system isn't one-size-fits-all. Flexible schemas and queries are essential.

## How Corrosion works

In a nutshell, Corrosion:

- Maintains a SQLite database on each node
- Gossips local changes throughout the cluster
- Uses [CR-SQLite](https://github.com/vlcn-io/cr-sqlite) for conflict resolution with CRDTs
- Uses [Foca](https://github.com/caio/foca) to manage cluster membership using a SWIM protocol
- Periodically synchronizes with a subset of other cluster nodes, to ensure consistency

## Features

- A flexible API to read from and write to Corrosion's store using SQL statements
- File-based schemas with on-the-fly updates
- HTTP streaming subscriptions based on SQL queries
- Live population of configuration files from Corrosion state with user-defined [Rhai](https://rhai.rs/) templates
- Storage and propagation of state from locally registered Consul services, replacing the central database with Corrosion's distributed state
- Secure peer-to-peer communication with the [QUIC](https://datatracker.ietf.org/doc/html/rfc9000) transport protocol (using [Quinn](https://github.com/quinn-rs/quinn))

## Usage overview

Run the Corrosion agent on every node/host in the cluster. Other programs running on the node use [Corrosion's HTTP API](https://superfly.github.io/corrosion/api/index.html) to query the local Corrosion SQLite database, add and update data, and subscribe to change notifications.

The [Corrosion CLI](https://superfly.github.io/corrosion/cli/index.html) provides commands for administration and access to database and features.

### Quick start

- [Prepare the Corrosion configuration file](https://superfly.github.io/corrosion/config/)
- [Specify the initial database schema](https://superfly.github.io/corrosion/schema.html)
- [Start the Corrosion agent](https://superfly.github.io/corrosion/cli/agent.html)

See the WIP [Corrosion documentation](https://superfly.github.io/corrosion/) for more details.

## Building Corrosion

Clone [https://github.com/superfly/corrosion.git](https://github.com/superfly/corrosion.git).

From within the repo directory:

```
cargo build --release && mv target/release/corrosion ./
```
