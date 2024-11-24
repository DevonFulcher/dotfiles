import json
import subprocess


def main():
    displays = subprocess.run(
        ["yabai", "-m", "query", "--displays"], check=True, capture_output=True
    )
    displays_dict = json.loads(displays.stdout)
    focused_display = list(filter(lambda d: d["has-focus"], displays_dict))[0]
    frame = focused_display["frame"]
    if frame["w"] / frame["h"] > 16 / 9:
        subprocess.run(["yabai", "-m", "window", "--grid", "1:2:1:0:1:1"], check=True)
    else:
        subprocess.run(
            ["yabai", "-m", "window", "--grid", "1:1:0:0:1:1"],
            check=True,
            capture_output=True,
        )


if __name__ == "__main__":
    main()
