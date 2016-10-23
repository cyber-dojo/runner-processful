#!/bin/sh

cid=$1         # Container ready to run /sandbox/cyber-dojo.sh
max_secs=$2    # How long cyber-dojo.sh has to complete, in seconds, eg 10

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Executes /sandbox/cyber-dojo.sh inside a docker container ${cid}
# prepared by docker_runner.rb
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# If it completes within max_seconds
#   o) the container is removed
#   o) it prints the output of cyber-dojo.sh's execution
#   o) it's exit status is 0 (success)
#
# If it fails to complete within max_seconds
#   o) the container is removed
#   o) it prints no output
#   o) it's exit status is 137 (see below)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# There are two places that run
#   docker rm --force ${cid} &> /dev/null
# I've tried putting that into a method to remove duplication
# and it causes tests to fail. I have no idea why!
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

success=0
timed_out_and_killed=137 # (128=timed-out) + (9=killed)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 1. After max_seconds, remove the container
#   o) Doing [docker stop ${CID}] is not enough to quickly stop a container
#      that is printing in an infinite loop (for example).
#   o) Any zombie processes this backgrounded process creates are reaped by tini.
#      See top of cyberdojo/runner's Dockerfile
#   o) The () puts the commands into a child process.
#   o) The trailing & backgrounds it.
#   o) Pipe stdout and stderr (&>) of both sub-commands to dev/null so normal
#      shell output [Terminated] from the pkill (3) is suppressed from output.
#
# Since this removes the container I've designed this shell script to
# always remove the container (see 4).
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

(sleep ${max_secs} &> /dev/null && docker rm --force ${cid} &> /dev/null) &
sleep_docker_rm_pid=$!

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 2. Run cyber-dojo.sh
# Don't use the exit-status of cyber-dojo.sh to determine
# the red/amber/green status. It's unreliable...
#   o) not all test frameworks set their exit-status properly
#   o) cyber-dojo.sh is editable (suppose it ended [exit 137])
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

output=$(docker exec \
               --user=nobody \
               --interactive \
               ${cid} \
               sh -c "cd /sandbox && ./cyber-dojo.sh 2>&1")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3. If the sleep-docker-rm process (1) is still alive race to
# kill it before it does [docker rm ${cid}]
#   o) pkill   => kill processes
#   o) -P PID  => whose parent pid is PID
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

pkill -P ${sleep_docker_rm_pid} &> /dev/null
if [ "$?" != "0" ]; then
  # Failed to kill the sleep-docker-rm process.
  # Assuming it ran to completion and removed the container
  # and that is what caused the [docker exec] to exit.
  exit ${timed_out_and_killed}
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 4. We're not using the exit status of the container (see 2)
# Removes the container (see 1)
# Echos the output so it can be red/amber/green regex'd
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "${output}"
docker rm --force ${cid} &> /dev/null
exit ${success}
