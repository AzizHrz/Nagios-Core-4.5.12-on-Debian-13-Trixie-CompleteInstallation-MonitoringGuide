# Nagios Core 4.5.12 on Debian 13 Trixie — Complete Installation & Monitoring Guide

![Nagios](https://img.shields.io/badge/Nagios-4.5.12-blue)
![Debian](https://img.shields.io/badge/Debian-13.4_Trixie-red)
![PHP](https://img.shields.io/badge/PHP-8.4-purple)
![Status](https://img.shields.io/badge/Status-In_Progress-yellow)
![License](https://img.shields.io/badge/License-GPL_v2-green)

> A practical, real-world installation guide for **Nagios Core 4.5.12** on **Debian 13.4 Trixie**,
> adapted from the OpenClassrooms course
> *"Mettez en place un outil de supervision de production avec Nagios"*.
> Unlike most tutorials written for older Debian versions, this guide documents every issue
> encountered on a modern Debian 13 bare-metal machine — with exact solutions for each.
> Includes automated install scripts, a full plugin reference (20+ plugins), and a growing
> troubleshooting section built from real errors.

---

## 🖥️ Final Result

**All 9 services green — 2 hosts monitored :**

![Final result all services OK](screenshots/s25-all-services-ok-9services.png)

**SSH service detail on Nagios Server :**

![SSH service detail](screenshots/s33-ssh-service-detail-ok.png)

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Architecture](#-architecture)
- [Quick Install](#-quick-install)
- [Part 1 — Server Preparation](#-part-1--server-preparation)
- [Part 2 — Nagios Core Compilation](#-part-2--nagios-core-compilation--install)
- [Part 3 — Plugins](#-part-3--plugins-installation)
- [Part 4 — Web Interface](#-part-4--web-interface)
- [Part 5 — Core Concepts](#-part-5--plugin-command-host-service)
- [Troubleshooting](#-troubleshooting)
- [Debian 9 vs Debian 13](#-debian-9-vs-debian-13-key-differences)
- [Plugins Reference](#-plugins-reference)
- [Next Steps](#-next-steps)

---

## ⚙️ Prerequisites

- Machine running **Debian 13.4 Trixie** (bare metal or VM)
- **sudo** access
- Active internet connection
- Minimum **2 GB RAM**, **20 GB disk**

---

## 🏗️ Architecture

```
[Debian 13.4 — Nagios Core 4.5.12]
         |
    [Apache2 + PHP 8.4]
         |
    http://[IP]/nagios
         |
   [Local Network]
   /      |       \
[localhost] [PCs] [VMs]
```

---

## 🚀 Quick Install

```bash
git clone https://github.com/[your-user]/nagios-debian13-guide.git
cd nagios-debian13-guide
sudo bash scripts/01-prepare-server.sh
sudo bash scripts/02-install-nagios-core.sh
sudo bash scripts/03-install-plugins.sh
sudo bash scripts/04-configure-nagios.sh
```

---

## 📖 Part 1 — Server Preparation

> Full guide → [docs/01-preparation-serveur.md](docs/01-preparation-serveur.md)

### Step 1 — Install Apache2 + PHP

On Debian 13, the first attempt with `php-imap` and `php-mcrypt` fails immediately:

![php-imap not found and apache install](screenshots/s04-php-imap-not-found-apache-install.png)

**What happened:** `php-imap` is not available on Debian 13, and running `apt-get` without `sudo` throws a permission denied error. The fix: use `sudo`, drop `php-mcrypt` (obsolete), and install `php-gd` and `php-curl` only at this stage.

### Step 2 — php-imap errors with multiple attempts

After installing PHP 8.4, `php-imap` and `php8.4-imap` both fail before adding Sury:

![php-imap errors on Debian 13](screenshots/s05-php-imap-errors-php84-not-found.png)

**What happened:** On Debian 13 with PHP 8.4, `php-imap` no longer exists as a generic package. Even `php8.4-imap` fails without the Sury repository.

### Step 3 — Add Sury repository

The Sury repository is the official PHP repository providing versioned packages for Debian:

![Sury repo setup and apt update](screenshots/s06-sury-repo-setup-update.png)

### Step 4 — php8.4-imap installed successfully from Sury

![php8.4-imap install success with imap confirmed](screenshots/s07-php84-imap-install-success.png)

`php -m | grep imap` confirms `imap` is active.

### Step 5 — Install libssl-dev and build tools

`libssl-dev` is **mandatory** on Debian 13. Without it, `./configure` will stop with
`Cannot find ssl headers`:

![libssl-dev kerberos and build tools install](screenshots/s12-libssl-dev-kerberos-install.png)

### Step 6 — Fix nagios home directory permissions

`sudo mkdir` creates folders owned by root. The nagios user cannot write to them.
Fix with `chown`:

![chown nagios home permissions fixed](screenshots/s09-nagios-home-chown-permissions.png)

### Step 7 — Apache2 running

![Apache2 active running status](screenshots/s08-apache2-active-running.png)

---

## 📖 Part 2 — Nagios Core Compilation & Install

> Full guide → [docs/02-installation-nagios-core.md](docs/02-installation-nagios-core.md)

### Step 1 — Download and extract Nagios 4.5.12

Download as nagios user from GitHub. Note the tar error when filename has special characters — correct command is `tar -zxvf nagios-4.5.12.tar.gz`:

![Nagios 4.5.12 download and extract](screenshots/s10-nagios-download-extract.png)

### Step 2 — make install fails as nagios user

Running `make install` as the nagios user fails because `/usr/local/nagios` is a
system directory owned by root:

![make install permission denied as nagios user](screenshots/s11-make-install-error-nagios-not-sudoers.png)

**Also visible:** `a2enmod` fails as nagios user (not in sudoers), `chown` fails,
`systemctl restart` fails. **Rule: all `make install` and system commands must be run
with `sudo` from primaryos.**

### Step 3 — sudo make install succeeds

Running from primaryos with sudo — files installed to `/usr/local/nagios/`:

![sudo make install success](screenshots/s13-sudo-make-install-success.png)

### Step 4 — Enable Apache modules and set permissions

`a2enmod rewrite`, `a2enmod cgi`, `chown -R nagios:nagcmd`, restart services:

![a2enmod rewrite cgi chown restart](screenshots/s14-a2enmod-rewrite-cgi-chown-restart.png)

### Step 5 — Nagios service running with workers

`systemctl status nagios` showing `active (running)` with all worker processes:

![Nagios service running with worker processes](screenshots/s15-nagios-service-running-workers.png)

---

## 📖 Part 3 — Plugins Installation

> Full guide → [docs/03-installation-plugins.md](docs/03-installation-plugins.md)

### Step 1 — Plugins download permission denied

Downloading as nagios user without sudo causes permission denied on the downloads folder:

![plugins download permission denied](screenshots/s16-plugins-download-permission-denied.png)

**Fix:** use `sudo wget` from primaryos, or fix permissions with `chown` first.

### Step 2 — Configure plugins from primaryos

Running `./configure` as primaryos with sudo (needed because folder ownership):

![plugins configure from primaryos](screenshots/s17-plugins-configure-primaryos.png)

### Step 3 — All plugins installed in libexec

After `sudo make install`, all standard plugins appear in `/usr/local/nagios/libexec/`:

![plugins installed in libexec](screenshots/s18-plugins-libexec-installed.png)

### Step 4 — Full plugin list

Complete list of all installed plugins:

![full plugin ls libexec](screenshots/s32-plugins-ls-all-libexec.png)

---

## 📖 Part 4 — Web Interface

> Full guide → [docs/04-configuration-interface.md](docs/04-configuration-interface.md)

### First access — Nagios 4.5.12 home page

First successful login to the Nagios web interface at `http://172.20.10.3/nagios`:

![Nagios web first access home](screenshots/s01-nagios-web-first-access-home.png)

### Alert history — errors before plugins (normal)

Immediately after first launch, before plugins are installed, all checks fail with
`No such file or directory`. **This is completely normal:**

![Nagios alerts before plugins installed](screenshots/s02-nagios-alerts-before-plugins.png)

### Alert history — after plugins installed

After plugins installation, the errors disappear. Only green OK alerts remain:

![Nagios alerts after plugins installed](screenshots/s03-nagios-alerts-after-plugins.png)

### Alert history — full history with OK and errors visible

Later alert history showing the transition from red errors to green OK:

![Nagios web alerts full history](screenshots/s20-nagios-web-alerts-history.png)

---

## 📖 Part 5 — Plugin, Command, Host, Service

> Full guide → [docs/05-nagios-core-concepts.md](docs/05-nagios-core-concepts.md)

Nagios works with **4 essential elements** that connect together:

```
Plugin → Command → Service → Host
```

### testNagios and restartNagios aliases

The two most important aliases for working with Nagios configuration.
Always run `testNagios` before `restartNagios`:

![testNagios and restartNagios aliases setup](screenshots/s21-aliases-testNagios-restartNagios.png)

### Adding Nagios Server as a new host

`localhost.cfg` showing both the default `localhost` host definition and the new
`Nagios Server` host definition added below:

![localhost.cfg host definition for Nagios Server](screenshots/s23-localhost-cfg-host-definition.png)

### testNagios — config OK with 2 hosts

After adding the Nagios Server host, `testNagios` shows 2 hosts checked, 0 errors:

![testNagios config ok 2 hosts](screenshots/s31-testNagios-ok-final-2hosts.png)

### Two hosts UP in the interface

Both `localhost` and `Nagios Server` showing UP status with PING OK:

![two hosts UP in Nagios interface](screenshots/s24-two-hosts-up-interface.png)

### commands.cfg — check-ssh-localhost + check_ping with -4

The `commands.cfg` file showing:
- New `check-ssh-localhost` command (hardcoded to localhost)
- `check_ping` with `-4` flag to force IPv4 (fix for hotspot IPv6 issue):

![commands.cfg with check-ssh-localhost and check_ping -4](screenshots/s27-commands-cfg-check-ssh-ping-ipv4.png)

### localhost.cfg — SSH service definition

The service definition for `SSH in Nagios Server` using `check-ssh-localhost`:

![localhost.cfg SSH service definition](screenshots/s28-localhost-cfg-ssh-service-definition.png)

### SSH install and plugin test

Installing `openssh-server`, starting the service, and verifying with `check_ssh localhost`:

![SSH install start and check_ssh test](screenshots/s26-ssh-install-test-plugin.png)

### ❌ testNagios — syntax error: command not defined

`testNagios` catches the error before restarting Nagios.
`check-ssh-localhost` is referenced in a service but not yet defined in `commands.cfg`:

![testNagios error command not defined](screenshots/s29-testNagios-error-command-not-defined.png)

### ✅ testNagios — all OK after fix

After adding `check-ssh-localhost` to `commands.cfg`, `testNagios` shows 0 errors:

![testNagios ok zero errors](screenshots/s19-testNagios-config-ok-zero-errors.png)

### Final result — all 9 services green

Both hosts up, all 9 services OK including SSH in Nagios Server:

![all services OK final](screenshots/s25-all-services-ok-9services.png)

---

## 🔧 Troubleshooting

> Full guide (16 problems documented) → [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

### IPv6 / DNS — check_ping fails with domain names

`ping google.com` works, `nslookup` resolves correctly with 8.8.8.8, but
`./check_ping -H google.com` returns CRITICAL because the hotspot blocks IPv6.
Fix: add `-4` to force IPv4:

![IPv6 DNS check_ping fix](screenshots/s34-ipv6-dns-check-ping-fix.png)

---

## 🔄 Debian 9 vs Debian 13 Key Differences

| Problem | Debian 9 | Debian 13 |
|---|---|---|
| `php-imap` | Available directly | ❌ Needs **Sury repo** → `php8.4-imap` |
| `php-mcrypt` | Available | ❌ Obsolete — remove from command |
| SSL headers | Included | ❌ Requires `libssl-dev` separately |
| Kerberos warning | None | ⚠️ Warning in `./configure` (ignorable) |
| `make install` | As nagios user | ❌ Must use `sudo` from primaryos |
| IPv6 | Not an issue | ⚠️ Hotspot blocks IPv6 → add `-4` |
| `usermod` | Without sudo | ❌ Requires explicit `sudo` |
| `.bashrc` for nagios | Works | ❌ nagios uses `sh` — use primaryos `~/.bashrc` |

---

## 🔌 Plugins Reference

### Standard (no extra prerequisites)

| Plugin | Usage |
|---|---|
| `check_ping` | Host availability via ICMP |
| `check_http` | Web server, SSL certificate |
| `check_ssh` | SSH service availability |
| `check_disk` | Disk space usage |
| `check_load` | CPU load average |
| `check_users` | Connected users count |
| `check_procs` | Running processes |
| `check_swap` | Swap memory usage |
| `check_tcp` | Any TCP port |
| `check_dns` | DNS resolution |
| `check_smtp` | Mail server |
| `check_ntp_time` | Clock sync |
| `check_ssl_validity` | SSL certificate expiry |
| `check_uptime` | System uptime |

### Optional (extra prerequisites needed)

```bash
sudo bash scripts/03-install-plugins.sh --with-mysql   # check_mysql
sudo bash scripts/03-install-plugins.sh --with-ldap    # check_ldap
sudo bash scripts/03-install-plugins.sh --with-smb     # check_disk_smb
sudo bash scripts/03-install-plugins.sh --with-snmp    # check_snmp
sudo bash scripts/03-install-plugins.sh --with-all     # everything
```

---

## 🔭 Next Steps

- [x] Nagios Core 4.5.12 installation ✅
- [x] Standard plugins 2.5 ✅
- [x] Plugin, Command, Host, Service documented ✅
- [x] Nagios Server as host + SSH service ✅
- [x] IPv6 hotspot fix ✅
- [x] testNagios & restartNagios workflow ✅
- [ ] NRPE — monitor remote machines
- [ ] Monitor Kali Linux VM on VirtualBox
- [ ] Security tools (Fail2ban, Wazuh)
- [ ] Email alerts

---

## 📚 Resources

- [OpenClassrooms Course](https://openclassrooms.com/fr/courses/2035786-mettez-en-place-un-outil-de-supervision-de-production-avec-nagios)
- [Nagios Core Official](https://www.nagios.org/projects/nagios-core/)
- [GitHub Nagios Core Releases](https://github.com/NagiosEnterprises/nagioscore/releases)
- [PHP Sury Repository](https://packages.sury.org/php/)
