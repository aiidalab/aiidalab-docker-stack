require(["base/js/namespace", "base/js/events"], (Jupyter, events) => {
  const parseLifetimeToMs = (str) => {
    const parts = str.split(":").map(Number);
    if (parts.length !== 3 || parts.some(isNaN)) {
      return null;
    }
    const [h, m, s] = parts;
    return ((h * 60 + m) * 60 + s) * 1000;
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

    const endTime = new Date(Date.now() + remainingMs);

    const formatTime = (seconds) => {
      const hrs = `${Math.floor(seconds / 3600)}`.padStart(2, "0");
      const mins = `${Math.floor((seconds % 3600) / 60)}`.padStart(2, "0");
      const secs = `${Math.floor(seconds % 60)}`.padStart(2, "0");
      return `${hrs}:${mins}:${secs}`;
    };

    const updateTimer = () => {
      const now = new Date();
      const timeLeft = (endTime - now) / 1000;
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

  loadCountdown = async () => {
    try {
      const response = await fetch("/static/custom/config.json");
      const config = await response.json();

      // Opt-in point for deployments
      if (!config.ephemeral) {
        return;
      }

      if (!config.expiry) {
        console.warn("Missing `expiry` in config file");
        return;
      }

      const expiry = new Date(config.expiry).getTime();
      const remaining = expiry - Date.now();

      insertCountdown(Math.max(0, remaining));
    } catch (err) {
      console.error("Countdown init failed:", err);
    }
  };

  events.on("app_initialized.NotebookApp", loadCountdown);
  loadCountdown();
});
