# Output

Small, shareable work product: summary tables, the numbers behind a figure in
the final report, a sweep comparison you want to keep.

Large artifacts do not go here. Checkpoints, TensorBoard logs and inference
dumps belong under `$NUGRAPH_LOG` on the cluster's project storage
(`/net/projects2/fermi2526/logs/$USER/`), and `.gitignore` blocks the usual file
types anywhere in the repo.

Generated figures (`*.png`, `*.pdf`, `*.html`) are gitignored too — commit the
notebook or script that draws them, so they can be regenerated, rather than the
images themselves.
