require(["base/js/namespace", "base/js/events"], (Jupyter, events) => {
  const parseLifetimeToMs = (str) => {
    // Supports MM:SS, HH:MM:SS, or D-HH:MM:SS formats
    const regex = /^(?:(\d+)-)?(?:(\d+):)?(\d+):(\d+)$/;
    const match = regex.exec(str.trim());

    if (!match) {
      console.warn("Invalid lifetime format:", str);
      return null;
    }

    const [_, days, hours, minutes, seconds] = match.map((v) => Number(v) || 0);

    const totalSeconds = days * 86400 + hours * 3600 + minutes * 60 + seconds;
    return totalSeconds * 1000;
  };

  const insertCountdown = (remainingMs) => {
    if (document.getElementById("culling-countdown")) {
      return;
    }

    const banner = document.createElement("div");
    banner.id = "culling-countdown";

    const shutdownWarning = document.createElement("div");
    shutdownWarning.id = "shutdown-warning";
    shutdownWarning.innerHTML = "⚠️ Shutdown imminent! ⚠️";
    banner.appendChild(shutdownWarning);

    const countdown = document.createElement("div");
    countdown.id = "countdown";
    countdown.innerHTML = `Session time remaining: `;
    const timer = document.createElement("span");
    timer.id = "culling-timer";
    timer.innerHTML = "Calculating...";
    countdown.appendChild(timer);
    banner.appendChild(countdown);

    const saveInfo = document.createElement("div");
    saveInfo.id = "save-info";
    saveInfo.innerHTML = `
      Consider saving your work using the <b>File Manager</b> or the <b>Terminal</b>
    `;
    banner.appendChild(saveInfo);

    const startTime = Date.now();
    const endTime = startTime + remainingMs;

    const formatTime = (seconds) => {
      const hrs = `${Math.floor(seconds / 3600)}`.padStart(2, "0");
      const mins = `${Math.floor((seconds % 3600) / 60)}`.padStart(2, "0");
      const secs = `${Math.floor(seconds % 60)}`.padStart(2, "0");
      // Format as HH:MM:SS, even if > 1 day (for now - rare?)
      return `${hrs}:${mins}:${secs}`;
    };

    const updateTimer = () => {
      const timeLeft = (endTime - Date.now()) / 1000;
      if (timeLeft < 0) {
        clearInterval(interval);
        return;
      }
      if (timeLeft < 1800) {
        banner.style.backgroundColor = "#DAA801";
        saveInfo.style.display = "block";
      }
      if (timeLeft < 300) {
        banner.style.backgroundColor = "red";
        shutdownWarning.style.display = "block";
        shutdownWarning.innerHTML = "⚠️ Shutdown imminent ⚠️";
      }
      timer.innerHTML = formatTime(timeLeft);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);

    const container = document.getElementById("header");
    if (container) {
      container.parentNode.insertBefore(banner, container);
    }
  };

  const loadCountdown = async () => {
    try {
      const [configResponse, uptimeResponse] = await Promise.all([
        fetch("/static/custom/config.json"),
        fetch("/uptime"),
      ]);

      const config = await configResponse.json();
      const uptimeData = await uptimeResponse.json();

      if (!config.ephemeral) {
        return;
      }

      if (!config.lifetime) {
        console.warn("Missing `lifetime` in config file");
        return;
      }

      const lifetimeMs = parseLifetimeToMs(config.lifetime);
      const uptimeMs = uptimeData.uptime * 1000;
      const remaining = lifetimeMs - uptimeMs;

      insertCountdown(Math.max(0, remaining));
    } catch (err) {
      console.error("Countdown init failed:", err);
    }
  };

  events.on("app_initialized.NotebookApp", loadCountdown);
  loadCountdown();
});
