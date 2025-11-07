# README.md

## Joomla Auto-Setup with DDEV

A single-command script to spin up a fresh **Joomla** instance in a local **DDEV** environment. It downloads Joomla (latest stable or a specific version), configures DDEV, boots containers, and performs an unattended Joomla installation — then opens the admin panel.

> **Good for:** onboarding new developers, quick demos, plugin/theme development, and clean test beds.

---

## Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [How It Works](#how-it-works)
4. [CLI Options & Examples](#cli-options--examples)
5. [What It Installs (Defaults)](#what-it-installs-defaults)
6. [Project Structure](#project-structure)
7. [Customization](#customization)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)
10. [Security Notes](#security-notes)
11. [Clean Up](#clean-up)

---

## Prerequisites

Make sure the following are installed on your machine:

* **Docker** (Engine + Desktop or CLI)
* **DDEV** ([https://ddev.readthedocs.io](https://ddev.readthedocs.io))
* **curl**
* **jq**
* **unzip**
* **bash** (macOS/Linux/WSL)

> **Check:**

```bash
docker --version

# DDEV must be in PATH
ddev version

curl --version
jq --version
unzip -v
```

If `jq`/`unzip` are missing:

* **Debian/Ubuntu**: `sudo apt-get update && sudo apt-get install -y jq unzip`
* **macOS (Homebrew)**: `brew install jq unzip`
* **Fedora**: `sudo dnf install -y jq unzip`

---

## Quick Start

1. Save the script as `setup_joomla.sh` and make it executable:

   ```bash
   chmod +x setup_joomla.sh
   ```
2. Run with a project name (downloads **latest** Joomla):

   ```bash
   ./setup_joomla.sh mysite
   ```
3. Or run with a **specific version** (e.g., `5.1.2`):

   ```bash
   ./setup_joomla.sh mysite 5.1.2
   ```
4. When the script finishes, it automatically launches **/administrator** in your browser.

---

## How It Works

High-level flow:

1. **Parse args** – reads `<project_name>` and optional `<joomla_version>`.
2. **Resolve download URL** –

   * If a version is provided, it builds: `https://github.com/joomla/joomla-cms/releases/download/${JOOMLA_VERSION}/Joomla_${JOOMLA_VERSION}-Stable-Full_Package.zip`.
   * Else it calls GitHub API for the **latest** release and uses `jq` to pick the **Stable Full Package** asset.
3. **Create project directory** – `mkdir "$PROJECT_NAME" && cd "$PROJECT_NAME"`.
4. **Download & extract** Joomla – `curl -L -o joomla.zip "$DOWNLOAD_URL" && unzip joomla.zip`.
5. **Configure DDEV** – `ddev config --project-type=php --webserver-type=apache-fpm --upload-dirs=images --project-name="$PROJECT_NAME"`.
6. **Start DDEV** – `ddev start` (brings up `web`, `db`, etc.).
7. **Unattended install** – runs `ddev php installation/joomla.php install ...` with site/admin/db flags.
8. **Open admin** – `ddev launch /administrator`.

---

## CLI Options & Examples

**Usage**

```bash
./setup_joomla.sh <project_name> [joomla_version]
```

**Examples**

```bash
# Latest Joomla
./setup_joomla.sh demo

# Specific Joomla version
./setup_joomla.sh demo 5.1.2
```

**Notes**

* `<project_name>` becomes the folder, the DDEV project name, and the site name.
* If you pass an invalid version, GitHub will 404 and the script will stop with unzip/curl errors. See **Troubleshooting**.

---

## What It Installs (Defaults)

* **Site name:** `$PROJECT_NAME`
* **Admin user:** `Administrator`
* **Admin username:** `admin`
* **Admin password:** `AdminAdmin1!` *(development only!)*
* **Admin email:** `admin@example.com`
* **DB type:** `mysql` (MariaDB in DDEV)
* **DB host/user/pass/name:** `db` / `db` / `db` / `db`
* **DB prefix:** `ddev_`
* **Public folder:** root (`""`)

> These are safe for local dev but **must** be changed for any shared/staging/production use.

---

## Project Structure

After running the script, your project directory (=`$PROJECT_NAME`) typically looks like:

```
$PROJECT_NAME/
├─ administrator/
├─ components/
├─ installation/      # used only during the automated install
├─ media/
├─ plugins/
├─ templates/
├─ images/
├─ configuration.php  # generated after install
├─ .ddev/             # DDEV configuration (docker-compose, config.yaml, etc.)
└─ ...
```

---

## Customization

You can adapt the script for team conventions.

### 1) Change Default Admin Credentials

Edit the `ddev php installation/joomla.php install` arguments:

```bash
--admin-user="Administrator" \
--admin-username=admin \
--admin-password="AdminAdmin1!" \
--admin-email="admin@example.com" \
```

> Consider reading values from env vars:

```bash
: "${JOOMLA_ADMIN_USER:=Administrator}"
: "${JOOMLA_ADMIN_USERNAME:=admin}"
: "${JOOMLA_ADMIN_PASSWORD:=AdminAdmin1!}"
: "${JOOMLA_ADMIN_EMAIL:=admin@example.com}"
```

Then swap flags to use these variables.

### 2) Change DB Settings

Similarly parameterize DB creds (still fine for local dev):

```bash
: "${DB_HOST:=db}"; : "${DB_USER:=db}"; : "${DB_PASS:=db}"; : "${DB_NAME:=db}"; : "${DB_PREFIX:=ddev_}"
```

### 3) Auto-install Extensions/Sample Data

After Joomla is installed, you can run CLI install for extensions or copy files:

```bash
# Example: install a package inside the container
# (Replace /var/www/html with the docroot if different)
ddev exec php cli/joomla.php extension:install /var/www/html/tmp/your-extension.zip
```

> Or add post-install steps (sample data, template, language packs) using Joomla CLI or scripted PHP.

### 4) Set PHP Version, Webserver, Upload Dirs

Edit the `ddev config` line. E.g. to switch to Nginx-FPM:

```bash
ddev config --project-type=php --webserver-type=nginx-fpm --upload-dirs=images,media --project-name="$PROJECT_NAME"
```

### 5) Non-Interactive Mode

The script is already non-interactive. If you add prompts later, always guard with defaults and `-y` flags in tools where relevant.

---

## Troubleshooting

**Curl fails with 404 or cannot find asset**

* Verify the version exists: visit the Joomla Releases page and confirm the asset name `Joomla_<version>-Stable-Full_Package.zip`.
* Try without a version to fetch the latest: `./setup_joomla.sh testsite`.

**`jq` not found**

* Install `jq` (see **Prerequisites**). The latest lookup requires it.

**Docker or DDEV not running**

* Start Docker Desktop/daemon.
* `ddev poweroff && ddev start` inside the project folder.

**Port conflicts (80/443)**

* Stop other local web servers (MAMP/XAMPP, Apache/Nginx) or reconfigure DDEV router: `ddev poweroff` then `ddev start`.

**Installation script path**

* If Joomla changes CLI paths in future versions, the command may differ. Current script uses: `installation/joomla.php install`.

**Windows**

* Use **WSL2** (Ubuntu) with Docker Desktop integration. Run the script from the Linux side.

---

## FAQ

**Q: Can I run multiple sites at once?**
Yes. Each site needs a unique folder and DDEV project name (the script uses `$PROJECT_NAME` for both).

**Q: Where are the DB and files stored?**
DB is in the DDEV `db` container volume; files are in your project folder. Use `ddev export-db`/`import-db` for backups.

**Q: How do I access phpMyAdmin?**
Run `ddev launch -p` (DDEV’s project services) or use `ddev describe` to find service URLs.

**Q: How do I change PHP settings?**
Add overrides in `.ddev/php/` (e.g., `php.ini`) and restart: `ddev restart`.

---

## Security Notes

* Credentials in this script are **for local development only**. Never reuse them in staging/production.
* If you commit the script, do **not** commit `.ddev` folders or `configuration.php` if they contain secrets.

---

## Clean Up

To stop and remove containers and volumes for the project:

```bash
cd $PROJECT_NAME
# stop containers
ddev stop
# remove DDEV project (keeps your code)
ddev delete -O
# optional: remove the project folder
cd .. && rm -rf $PROJECT_NAME
```

---

## Script (for reference)

> Save as `setup_joomla.sh` and `chmod +x setup_joomla.sh`.

```bash
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
```

---

# docs.html

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Joomla DDEV Auto-Setup — Developer Guide</title>
  <style>
    :root { --bg:#0e1116; --card:#151a22; --text:#e7ecf3; --muted:#a5b0c0; --accent:#69b8ff; --ok:#7ed957; --warn:#ffd166; }
    *{box-sizing:border-box}
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Arial,sans-serif;background:var(--bg);color:var(--text);line-height:1.6}
    header{position:sticky;top:0;background:rgba(14,17,22,.8);backdrop-filter:saturate(1.2) blur(6px);border-bottom:1px solid #202531}
    .wrap{max-width:980px;margin:0 auto;padding:24px}
    h1{font-size:32px;margin:8px 0 0}
    p.lead{color:var(--muted);margin:8px 0 0}
    nav{display:flex;gap:12px;flex-wrap:wrap;margin-top:12px}
    nav a{padding:8px 12px;border-radius:999px;background:#1b222d;color:var(--muted);text-decoration:none;border:1px solid #232a37}
    nav a:hover{color:var(--text);border-color:#2d3647}
    section{background:var(--card);border:1px solid #1f2633;border-radius:16px;padding:20px;margin:24px 0}
    h2{margin-top:0}
    code, pre{font-family:ui-monospace,Menlo,Consolas,monospace}
    pre{background:#0f141c;border:1px solid #1c2432;padding:14px;border-radius:12px;overflow:auto}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px}
    .callout{border-left:4px solid var(--accent);padding:8px 12px;background:#0f141c;border-radius:8px}
    .badge{display:inline-block;padding:2px 8px;border-radius:6px;border:1px solid #2b3547;background:#141a24;color:var(--muted);font-size:12px}
    .ok{color:var(--ok)}.warn{color:var(--warn)}
    footer{color:var(--muted);text-align:center;padding:32px 0}
  </style>
</head>
<body>
  <header>
    <div class="wrap">
      <h1>Joomla DDEV Auto-Setup</h1>
      <p class="lead">Spin up a clean Joomla site locally with a single command.</p>
      <nav>
        <a href="#prereq">Prerequisites</a>
        <a href="#quickstart">Quick Start</a>
        <a href="#how">How it Works</a>
        <a href="#customize">Customization</a>
        <a href="#trouble">Troubleshooting</a>
        <a href="#faq">FAQ</a>
        <a href="#security">Security</a>
      </nav>
    </div>
  </header>

  <main class="wrap">
    <section id="prereq">
      <h2>Prerequisites</h2>
      <div class="grid">
        <div><span class="badge">Required</span><pre><code>Docker
DDEV
curl
jq
unzip
bash</code></pre></div>
        <div>
          <div class="callout">
            Check your tools:
            <pre><code>docker --version
ddev version
curl --version
jq --version
unzip -v</code></pre>
          </div>
        </div>
      </div>
    </section>

    <section id="quickstart">
      <h2>Quick Start</h2>
      <pre><code># Save & make executable
chmod +x setup_joomla.sh

# Latest Joomla
./setup_joomla.sh mysite

# Specific version
./setup_joomla.sh mysite 5.1.2</code></pre>
      <p class="ok">The script opens <code>/administrator</code> when done.</p>
    </section>

    <section id="how">
      <h2>How it Works</h2>
      <ol>
        <li>Parse args: <code>&lt;project_name&gt; [joomla_version]</code>.</li>
        <li>Resolve download URL via GitHub API (latest) or fixed version.</li>
        <li>Create project dir and extract Joomla.</li>
        <li>Configure and start DDEV.</li>
        <li>Run unattended Joomla installer via CLI.</li>
        <li>Launch the admin panel.</li>
      </ol>
      <pre><code>ddev php installation/joomla.php install \
  --site-name=&quot;$PROJECT_NAME&quot; \
  --admin-username=admin \
  --admin-password=&quot;AdminAdmin1!&quot; \
  --db-host=db --db-user=db --db-pass=db --db-name=db</code></pre>
    </section>

    <section id="customize">
      <h2>Customization</h2>
      <div class="grid">
        <div>
          <h3>Credentials via env</h3>
          <pre><code>export JOOMLA_ADMIN_PASSWORD='ChangeMe123!'
./setup_joomla.sh mysite</code></pre>
        </div>
        <div>
          <h3>Switch web server</h3>
          <pre><code>ddev config --webserver-type=nginx-fpm</code></pre>
        </div>
        <div>
          <h3>Install extensions</h3>
          <pre><code>ddev exec php cli/joomla.php \
  extension:install /var/www/html/tmp/your.zip</code></pre>
        </div>
      </div>
    </section>

    <section id="trouble">
      <h2>Troubleshooting</h2>
      <ul>
        <li><strong>404 on download:</strong> verify the version asset name.</li>
        <li><strong>Missing jq:</strong> install via your package manager.</li>
        <li><strong>Docker not running:</strong> start Docker Desktop/daemon.</li>
        <li><strong>Port conflicts 80/443:</strong> stop other local servers or restart DDEV.</li>
      </ul>
      <pre><code>ddev poweroff && ddev start</code></pre>
    </section>

    <section id="faq">
      <h2>FAQ</h2>
      <p><strong>Multiple sites?</strong> Yes, use different project names.</p>
      <p><strong>DB access?</strong> Use <code>ddev launch -p</code> or <code>ddev describe</code>.</p>
      <p><strong>PHP config?</strong> Add overrides in <code>.ddev/php/</code> and restart.</p>
    </section>

    <section id="security">
      <h2>Security Notes</h2>
      <p class="warn">The default admin password and DB creds are for <em>local development only</em>. Change them for any non-local usage.</p>
    </section>

    <footer>
      Built for fast onboarding. Happy hacking! 🚀
    </footer>
  </main>
</body>
</html>
```

