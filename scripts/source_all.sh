# Check if a directory path was provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/directory"
  exit 1
fi

# Define the directory containing the files to source
DIRECTORY="$1"

# Check if the directory exists
if [ ! -d "$DIRECTORY" ]; then
  return 0
fi

# Enable nullglob to handle empty directories gracefully
shopt -s nullglob 2>/dev/null || setopt null_glob 2>/dev/null

# Loop through each file in the directory
for FILE in "$DIRECTORY"/*
do
  # Source the file
  if [ -f "$FILE" ]; then
    . "$FILE"
  fi
done
