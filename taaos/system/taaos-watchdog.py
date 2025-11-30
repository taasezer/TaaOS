#!/usr/bin/env python3
"""
TaaOS Watchdog (Self-Healing Service)
Monitors system health and automatically fixes common issues.
"""

import time
import subprocess
import logging
import os

# Configure Logging
logging.basicConfig(
    filename='/var/log/taaos/watchdog.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def check_internet():
    """Check internet connectivity and restart networking if down."""
    try:
        subprocess.check_call(['ping', '-c', '1', '8.8.8.8'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        logging.warning("Internet connection lost. Attempting to restart NetworkManager...")
        try:
            subprocess.run(['systemctl', 'restart', 'NetworkManager'], check=True)
            logging.info("NetworkManager restarted.")
            time.sleep(10) # Wait for reconnection
            return False
        except Exception as e:
            logging.error(f"Failed to restart network: {e}")
            return False

def check_disk_space():
    """Check root disk space and clean cache if low (< 1GB)."""
    try:
        df = subprocess.check_output(['df', '/'], text=True).splitlines()[1]
        available = int(df.split()[3]) # Available blocks (1K)
        
        if available < 1048576: # Less than 1GB
            logging.warning("Low disk space detected. Running cleanup...")
            subprocess.run(['taaos-cleanup', '--auto'], check=True)
            logging.info("Cleanup completed.")
    except Exception as e:
        logging.error(f"Disk check failed: {e}")

def check_failed_services():
    """Check for failed systemd units and try to restart them."""
    try:
        output = subprocess.check_output(['systemctl', '--failed', '--no-legend'], text=True)
        if output:
            for line in output.splitlines():
                unit = line.split()[0]
                logging.warning(f"Service {unit} failed. Attempting restart...")
                subprocess.run(['systemctl', 'restart', unit])
                logging.info(f"Restart command sent for {unit}")
    except Exception as e:
        logging.error(f"Service check failed: {e}")

def main():
    logging.info("TaaOS Watchdog started.")
    while True:
        check_internet()
        check_disk_space()
        check_failed_services()
        time.sleep(300) # Run every 5 minutes

if __name__ == '__main__':
    # Ensure log directory exists
    os.makedirs('/var/log/taaos', exist_ok=True)
    main()
