# Copy workload view

An unofficial k9s plugin that copies a **best-effort** `kubectl` command for workload views. Press `Ctrl-Y` on a selected workload row, then paste the command into a shell or a message.

The plugin uses the selected object's owner and label selector to make useful commands for related Pods, Jobs, and ReplicaSets. For other workload lists it copies `kubectl get <resource> -n <namespace> --context <context>`.

## Install

Requires k9s with standalone plugin snippets (v0.40.9 or newer), Bash 3.2+, `kubectl`, `jq`, and a clipboard command: `pbcopy` (macOS), `wl-copy`, `xclip`, or `xsel` (Linux).

1. From the repository root, put the executable on the `PATH` used to launch k9s:

   ```sh
   mkdir -p "$HOME/.local/bin"
   install -m 755 bin/k9s-copy-workload-view "$HOME/.local/bin/k9s-copy-workload-view"
   command -v k9s-copy-workload-view
   ```

   If the last command cannot find it, add `$HOME/.local/bin` to your shell's `PATH` before launching k9s.

2. Run `k9s info` and find the **Plugins** file. Create a `plugins` directory next to it, then copy [`plugins/copy-workload-view.yaml`](../plugins/copy-workload-view.yaml) into that directory. For example, on macOS with k9s's default location:

   ```sh
   mkdir -p "$HOME/Library/Application Support/k9s/plugins"
   cp plugins/copy-workload-view.yaml "$HOME/Library/Application Support/k9s/plugins/"
   ```

   On Linux the usual directory is `~/.config/k9s/plugins/`. The location shown by `k9s info` takes precedence. If `Ctrl-Y` is already assigned in one of these views, change `shortCut` in the snippet.

3. Restart k9s. Press `?` in a supported view to confirm the shortcut appears.

The repository keeps the snippet separate from your existing `plugins.yaml`, so installing it does not overwrite other plugins.

## What it copies

| Selected row | Copied query |
| --- | --- |
| Pod owned by a Deployment, StatefulSet, DaemonSet, Job, ReplicaSet, or ReplicationController | `kubectl get pods -l <owner selector>` |
| Job owned by a CronJob | A `kubectl`/`jq` pipeline selecting Jobs by CronJob owner UID |
| ReplicaSet owned by a Deployment | `kubectl get replicasets -l <deployment selector>` |
| Other supported workload row | `kubectl get <resource>` in the selected row's namespace and context |

The plugin itself makes only read-only `kubectl get` requests. It copies the generated command; it does not run that command.

## Limits

k9s plugins expose the selected object but not the full navigation path. The command may differ from the screen: a plain Pods or Jobs list can copy a query for the selected item's owner, and an all-namespaces view is narrowed to the selected row's namespace. k9s text filters and table formatting are not exported. Check a pasted command before sharing it as an exact reproduction of a view.

## Test

Run `bash tests/copy-workload-view.sh` from the repository root. It uses sample Kubernetes objects and never contacts a cluster.

## License

MIT. See [LICENSE](../LICENSE).
