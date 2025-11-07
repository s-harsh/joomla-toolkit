#!/bin/bash
# Usage: ./setup_joomla.sh <project_name> <joomla_version>
# Example: ./setup_joomla.sh testsite 5.1.2

PROJECT_NAME=$1
JOOMLA_VERSION=$2

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Please provide a project name."
  echo "👉 Usage: ./setup_joomla.sh <project_name> [joomla_version]"
  exit 1
fi

if [ -z "$JOOMLA_VERSION" ]; then
  echo "⚙️  No Joomla version provided. Downloading latest stable release..."
  DOWNLOAD_URL=$(curl -sL https://api.github.com/repos/joomla/joomla-cms/releases/latest | jq -r '.assets | map(select(.name | test("^Joomla.*Stable-Full_Package\\.zip$")))[0].browser_download_url')
else
  echo "⬇️  Downloading Joomla version $JOOMLA_VERSION ..."
  DOWNLOAD_URL="https://github.com/joomla/joomla-cms/releases/download/${JOOMLA_VERSION}/Joomla_${JOOMLA_VERSION}-Stable-Full_Package.zip"
fi

# Create and move into project directory
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Download and extract Joomla
curl -L -o joomla.zip "$DOWNLOAD_URL"
unzip joomla.zip >/dev/null
rm joomla.zip

# Configure DDEV
ddev config --project-type=php --webserver-type=apache-fpm --upload-dirs=images --project-name="$PROJECT_NAME"

# Start DDEV
ddev start

# Install Joomla automatically
ddev php installation/joomla.php install \
  --site-name="$PROJECT_NAME" \
  --admin-user="Administrator" \
  --admin-username=admin \
  --admin-password="AdminAdmin1!" \
  --admin-email="admin@example.com" \
  --db-type=mysql \
  --db-encryption=0 \
  --db-host=db \
  --db-user=db \
  --db-pass="db" \
  --db-name=db \
  --db-prefix=ddev_ \
  --public-folder=""

echo "✅ Joomla $JOOMLA_VERSION setup complete!"
echo "🌐 Launching admin panel..."
ddev launch /administrator
