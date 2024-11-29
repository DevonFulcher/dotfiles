import time
import logging

from git_pr import process_prs, read_pr_info

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def main():
    logging.info("Starting PR monitoring daemon")
    while True:
        prs = read_pr_info()
        process_prs(prs)
        time.sleep(3600)


if __name__ == "__main__":
    main()
