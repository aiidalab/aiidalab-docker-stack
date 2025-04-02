import re
import subprocess

from notebook.base.handlers import IPythonHandler
from notebook.utils import url_path_join


class UptimeHandler(IPythonHandler):
    def get(self):
        try:
            output = subprocess.check_output(["ps", "-p", "1", "-o", "etime="])
            etime = output.decode("utf-8").strip()
            seconds = self._parse_etime_to_seconds(etime)
            self.finish({"uptime": seconds})
        except Exception as e:
            self.set_status(500)
            self.finish({"error": str(e)})

    def _parse_etime_to_seconds(self, etime):
        # Supports MM:SS, HH:MM:SS, or D-HH:MM:SS formats
        match = re.match(r"(?:(\d+)-)?(?:(\d+):)?(\d+):(\d+)", etime)
        if not match:
            raise ValueError(f"Unrecognized etime format: {etime}")

        days, hours, minutes, seconds = match.groups(default="0")
        return int(days) * 86400 + int(hours) * 3600 + int(minutes) * 60 + int(seconds)


def load_jupyter_server_extension(nb_server_app):
    web_app = nb_server_app.web_app
    route = url_path_join(web_app.settings["base_url"], "/uptime")
    web_app.add_handlers(".*", [(route, UptimeHandler)])
