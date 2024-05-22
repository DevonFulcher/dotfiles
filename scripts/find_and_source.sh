# Check if a directory path and target value were provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 /path/to/directory target_value"
  exit 1
fi

# Define the directory containing the files and the target value to match
DIRECTORY="$1"
TARGET_VALUE="$2"

# Check if the directory exists
if [ ! -d "$DIRECTORY" ]; then
  echo "Error: Directory $DIRECTORY does not exist."
  exit 1
fi

# Loop through each file in the directory, including dotfiles
find "$DIRECTORY" -type f -print | while read -r FILE; do
  # Get the filename without the path
  FILENAME=$(basename "$FILE")
  
  # Remove the suffix '_zshrc.sh' from the filename
  BASENAME="${FILENAME%_zshrc.sh}"
  
  # Check if the basename matches the target value
  if [ "$BASENAME" = "$TARGET_VALUE" ]; then
    # Source the file using the POSIX-compliant dot command
    if [ -f "$FILE" ]; then
      . "$FILE"
    fi
  fi
done
