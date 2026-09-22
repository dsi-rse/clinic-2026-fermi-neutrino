# First assignment: connect to the cluster and run a small job

The first assignment has 6 parts: be sure to do all of them!

## 1. Connect to the cluster with ssh

Open a terminal (Powershell on Windows; Utilities → Terminal on Mac) and

```bash
ssh <cnetid>@login.ds.uchicago.edu
```

Documentation: https://cluster-policy.ds.uchicago.edu/quickstart/ssh/

You should see this message (or one like it):

```
###############################################################################
#                                                                             #
#   *****  IMPORTANT NOTICE: DO NOT RUN COMPUTE JOBS ON LOGIN NODE  *****     #
#                                                                             #
#  The login node is for connecting, editing, and submitting jobs only!       #
#                                                                             #
#  High-intensive compute jobs must be submitted through the SLURM scheduler. #
#  Use interactive sessions or submit batch jobs as appropriate.              #
#                                                                             #
#       Failure to comply may result in job termination without notice.       #
#                                                                             #
#                 For help, contact techstaff@cs.uchicago.edu                 #
#                                                                             #
###############################################################################
```

## 2. Go to the project directory and make sure you can access it

_Within the ssh session_, run

```bash
cd /net/projects2/fermi2526
```

If that works (no error message), do

```bash
touch hello-$USER.txt
rm hello-$USER.txt
```

which creates and deletes a file based on your username.

## 3. Clone your own copy of the git repository

In the same directory,

```bash
git clone --recursive https://github.com/dsi-rse/clinic-2026-fermi-neutrino.git clinic-2026-fermi-neutrino-$USER
```

This is your copy of the code, separate from everyone else's, so that you don't overwrite other people's work. In the future, when you log in, go to

```bash
cd /net/projects2/fermi2526/clinic-2026-fermi-neutrino-$USER/
```

to start working.

## 4. Configure the software environment

Run the following commands to get the software configured:

```bash
source /etc/profile.d/conda.sh
conda activate /net/projects2/fermi2526/conda/nugraph-25-10
cd /net/projects2/fermi2526/clinic-2026-fermi-neutrino-$USER/external/NuGraph
export NUGRAPH_LOG=$PWD/logs
pip install --no-deps -e nugraph/
pip install --no-deps -e pynuml/
```

and then test it:

```bash
python -c 'import torch; print(torch.__version__)'
```

You should see **[FIXME: what version should they see?]**

## 5. Set up remote VSCode and run a terminal in it

You'll need VSCode to do your work, but following cluster rules, VSCode needs to run on your own computer with a remote connection to the cluster.

How to do that: https://clinic.ds.uchicago.edu/tutorials/slurm.html#set-up-vs-code-to-use-the-cluster

You'll know that it's working when you can (a) see your /net/projects2/fermi2526/clinic-2026-fermi-neutrino-$USER/ files and (b) run the `python -c 'import torch; print(torch.__version__)'` test in VSCode's internal terminal.

## 6. Run a job on the cluster

Use VSCode to make a file named `slurm/quick-test.sbatch` in your copy of the repo, then put the following in it:

```slurm
#!/bin/bash

#SBATCH --job-name=quick-test
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0:05:00
#SBATCH --output=logs/slurm-%x-%j.out
#SBATCH --open-mode=append

set -eo pipefail
cd "${SLURM_SUBMIT_DIR:-$PWD}"

source /etc/profile.d/conda.sh
conda activate /net/projects2/fermi2526/conda/nugraph-25-10
cd /net/projects2/fermi2526/clinic-2026-fermi-neutrino-$USER/external/NuGraph
export NUGRAPH_LOG=$PWD/logs
pip install --no-deps -e nugraph/
pip install --no-deps -e pynuml/

uname
python -c 'import torch; print(torch.__version__)'
```

In a terminal (possibly VSCode's), run it with

```bash
sbatch slurm/quick-test.sbatch
```

Check the status of your job with

```bash
squeue -u $USER
```

and when it finishes, check the output in the `logs/slurm-quick-test-<jobid>.out` (normal print-outs) and `logs/slurm-quick-test-<jobid>.err` (errors) files that it creates.

Once you've done that, you're done!
