import sys
import subprocess


def main():
    # Get all command line arguments except the script name
    git_args = sys.argv[1:]

    # Check if the command is 'pr'
    if git_args and git_args[0] == "pr":
        subprocess.run(["gh", "pr", "view", "--web"], check=True)
    else:
        # Construct the git command
        command = ["git"] + git_args

        try:
            # Run the git command and capture the output
            result = subprocess.run(command, check=True, text=True, capture_output=True)

            # Print the output
            print(result.stdout, end="")
            print(result.stderr, end="", file=sys.stderr)

            # Exit with the same status code as the git command
            sys.exit(result.returncode)
        except subprocess.CalledProcessError as e:
            # If the git command fails, print the error and exit with the error code
            print(e.stdout, end="")
            print(e.stderr, end="", file=sys.stderr)
            sys.exit(e.returncode)


if __name__ == "__main__":
    main()
