#!/bin/bash
# linux-auth-sim.sh
# Simulates SSH brute force and sudo abuse for SIEM detection testing — LAB USE ONLY
# Run on your Linux VM to generate auth.log entries

set -e

TARGET_HOST="${1:-localhost}"
TARGET_USER="${2:-labuser}"
ATTEMPT_COUNT="${3:-10}"

echo "============================================="
echo "  LINUX AUTH SIMULATION — LAB USE ONLY"
echo "  Target: $TARGET_HOST | User: $TARGET_USER"
echo "  Attempts: $ATTEMPT_COUNT"
echo "============================================="
echo ""

# ─── SSH Brute Force Simulation ───────────────────────────────────────────────
echo "[*] Simulating SSH brute force ($ATTEMPT_COUNT attempts)..."
echo "    This generates 'Failed password' entries in /var/log/auth.log"
echo ""

FAKE_PASSWORDS=("password123" "admin" "letmein" "welcome1" "qwerty" "abc123" "monkey" "dragon" "master" "pass1234")
FAILURES=0

for i in $(seq 1 $ATTEMPT_COUNT); do
    PASS=${FAKE_PASSWORDS[$(( (i-1) % ${#FAKE_PASSWORDS[@]} ))]}

    # Use sshpass with bad password — will fail and log to auth.log
    if command -v sshpass &>/dev/null; then
        sshpass -p "$PASS" ssh \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=2 \
            -o BatchMode=no \
            "${TARGET_USER}@${TARGET_HOST}" exit 2>/dev/null || true
    else
        # Fallback: use SSH without sshpass (will also fail and log)
        ssh -o StrictHostKeyChecking=no \
            -o ConnectTimeout=2 \
            -o BatchMode=yes \
            "${TARGET_USER}@${TARGET_HOST}" exit 2>/dev/null || true
    fi

    FAILURES=$((FAILURES + 1))
    echo "  [-] Attempt $i: FAILED — user=$TARGET_USER pass=$PASS"
    sleep 0.3
done

echo ""
echo "[+] SSH simulation complete. Failures: $FAILURES"
echo ""

# ─── Sudo Abuse Simulation ────────────────────────────────────────────────────
echo "[*] Simulating sudo usage (generates sudo log entries)..."

# Run harmless sudo commands to generate audit trail
sudo -n id 2>/dev/null && echo "  [+] sudo id: success" || echo "  [-] sudo id: failed (expected if no NOPASSWD)"
sudo -n whoami 2>/dev/null && echo "  [+] sudo whoami: success" || echo "  [-] sudo whoami: failed"
sudo -n ls /root 2>/dev/null && echo "  [+] sudo ls /root: success" || echo "  [-] sudo ls /root: failed"

echo ""

# ─── Failed Sudo Simulation ───────────────────────────────────────────────────
echo "[*] Simulating failed sudo authentication..."
# This generates 'authentication failure' in auth.log
echo "wrongpassword" | sudo -S id 2>/dev/null || true
echo "wrongpassword" | sudo -S whoami 2>/dev/null || true
echo "  [-] Failed sudo attempts generated"
echo ""

# ─── Verify Logs Generated ───────────────────────────────────────────────────
echo "─────────────────────────────────────────────"
echo "  Simulation complete. Verifying log entries:"
echo ""

LOG_FILE="/var/log/auth.log"
[ -f "/var/log/secure" ] && LOG_FILE="/var/log/secure"  # RHEL/CentOS

echo "  Last 10 auth entries:"
sudo tail -10 "$LOG_FILE" 2>/dev/null || tail -10 "$LOG_FILE" 2>/dev/null || echo "  (run as root to see auth.log)"

echo ""
echo "  ELK KQL to verify:"
echo "  alert_type:\"ssh_failed_password\" | date range: last 5 minutes"
echo ""
echo "  Splunk SPL to verify:"
echo "  index=siem_linux \"Failed password\" | head 20"
echo "─────────────────────────────────────────────"
