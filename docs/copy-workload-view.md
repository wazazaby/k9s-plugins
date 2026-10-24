# Copy workload view

Press `Ctrl-Y` on a workload row to copy a **best-effort** `kubectl` command. The plugin uses owner references and label selectors to find related Pods, Jobs, and ReplicaSets. For other workloads, it copies a `kubectl get` command for the selected row's resource, namespace, and context.

## Install

Requires k9s v0.40.9+ (standalone plugin snippets), Bash 3.2+, `kubectl`, `jq`, and a clipboard command: `pbcopy` (macOS), `wl-copy`, `xclip`, or `xsel` (Linux).

1. From the repository root, install the helper on the `PATH` used to launch k9s:

   ```sh
   mkdir -p "$HOME/.local/bin"
   install -m 755 bin/k9s-copy-workload-view "$HOME/.local/bin/k9s-copy-workload-view"
   command -v k9s-copy-workload-view
   ```

   If the last command cannot find it, add `$HOME/.local/bin` to your shell's `PATH` before launching k9s.

2. Run `k9s info` and find the **Plugins** file. Create a `plugins` directory beside it and copy [`plugins/copy-workload-view.yaml`](../plugins/copy-workload-view.yaml) there. On macOS with the default location:

   ```sh
   mkdir -p "$HOME/Library/Application Support/k9s/plugins"
   cp plugins/copy-workload-view.yaml "$HOME/Library/Application Support/k9s/plugins/"
   ```

   On Linux the usual directory is `~/.config/k9s/plugins/`. The location shown by `k9s info` takes precedence. If `Ctrl-Y` is already assigned in one of these views, change `shortCut` in the snippet.

3. Restart k9s. Press `?` in a supported view to confirm the shortcut appears.

## What it copies

| Selected row | Copied query |
| --- | --- |
| Pod owned by a Deployment, StatefulSet, DaemonSet, Job, ReplicaSet, or ReplicationController | `kubectl get pods -l <owner selector>` |
| Job owned by a CronJob | A `kubectl`/`jq` pipeline selecting Jobs by CronJob owner UID |
| ReplicaSet owned by a Deployment | `kubectl get replicasets -l <deployment selector>` |
| Other supported workload row | `kubectl get <resource>` in the selected row's namespace and context |

The plugin itself makes only read-only `kubectl get` requests. It copies the generated command; it does not run that command.

## Limits

k9s plugins expose the selected object, but not the full navigation path. A plain Pods or Jobs list may copy a query for the selected item's owner. An all-namespaces view produces a command for the selected row's namespace. Text filters and table formatting are not exported. Check the command before sharing it as an exact reproduction of a view.

## Test

Run `bash tests/copy-workload-view.sh` from the repository root. It uses sample Kubernetes objects and never contacts a cluster.
