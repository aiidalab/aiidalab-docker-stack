# Self-hosted runners

For building `aarch64` images, we use self-hosted GitHub runners.
The runner is hosted on the apple silicon machine in PSI.

Configure your runner:

1. Run under `root`:

    XXX: change the xx to the correct repo name after merged
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/xx/HEAD/aarch64-runner/setup.sh)"
   ```

   This will perform the initial runner setup and create a user `runner-user`.

2. Run under `root`, Start docker service, we use [`colima`](https://github.com/abiosoft/colima) as the container runtime:

   ```bash
   colima start
   ```

   This command needs to be run every time after reboot. *(TODO: make it auto start on boot)*

3. Setup new GitHub Runner under `runner-user` using [GitHub Instructions](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners).
   **Do not `./run.sh` yet**.
   **In the first step, use folder `actions-runner-aiidalab` to distinguish from the other runners.**

4. Run under `runner-user`, install the runner as a service:

   ```bash
   cd /Users/runner-user/actions-runner-aiidalab/ && ./svc.sh install
   ```
   This will create the plist file for the runner service, it is not able to run it with the non-gui user.
   As shown in the [issue](https://github.com/actions/runner/issues/1056#issuecomment-1237426462), real services start on boot, not on login so on macOS this means the service needs to be a `LaunchDaemon` and not a `LaunchAgent`.

   In case the python path is not correct, change the `runsvc.sh` file to the correct path.
   Since we use `colima` as the container runtime, the docker sock is located at `unix://$HOME/.colima/default/docker.sock`.
   Change the `runsvc.sh` file to:

   ```bash
   #!/bin/bash

   # convert SIGTERM signal to SIGINT
   # for more info on how to propagate SIGTERM to a child process see: http://veithen.github.io/2014/11/16/sigterm-propagation.html
   trap 'kill -INT $PID' TERM INT

   if [ -f ".path" ]; then
      # configure
      export PATH=`cat .path`
      eval "$(/opt/homebrew/bin/brew shellenv)"
      export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"
      export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock
      echo ".path=${PATH}"
   fi

   nodever=${GITHUB_ACTIONS_RUNNER_FORCED_NODE_VERSION:-node16}

   # insert anything to setup env when running as a service
   # run the host process which keep the listener alive
   ./externals/$nodever/bin/node ./bin/RunnerService.js &
   PID=$!
   wait $PID
   trap - TERM INT
   wait $PID
   ```

   ```bash
   sudo mv /Users/runner-user/Library/LaunchAgents/actions.runner.*.plist /Library/LaunchDaemons/
   sudo chown root:wheel /Library/LaunchDaemons/actions.runner.*.plist
   sudo /bin/launchctl load /Library/LaunchDaemons/actions.runner.aiidalab.Jusong-MacBook-Air.plist
   ```

5. Reboot the VM to apply all updates and run GitHub runner.
