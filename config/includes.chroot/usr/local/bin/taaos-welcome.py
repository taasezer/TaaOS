#!/usr/bin/env python3
# =============================================================================
# TaaOS Mac-Style First Boot Welcome Screen
# =============================================================================
# Shows multilingual greetings with smooth fade animation on first boot.
# Requires: python3-tk (Tkinter)
# =============================================================================
import os
import sys
import time
import subprocess

# Only run once per user
FLAG_FILE = os.path.expanduser("~/.config/taaos-welcome-done")

if os.path.exists(FLAG_FILE):
    sys.exit(0)

# Wait for display server to be ready
def wait_for_display(max_wait=30):
    """Wait until DISPLAY is available and X server responds."""
    for i in range(max_wait):
        display = os.environ.get("DISPLAY")
        if display:
            try:
                result = subprocess.run(
                    ["xdpyinfo"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    timeout=2
                )
                if result.returncode == 0:
                    return True
            except (subprocess.TimeoutExpired, FileNotFoundError):
                pass
        time.sleep(1)
    return False

if not wait_for_display():
    sys.exit(1)

# Now try to import Tkinter
try:
    import tkinter as tk
except ImportError:
    # Fallback: show a simple zenity dialog if Tkinter is not available
    try:
        subprocess.Popen([
            "zenity", "--info",
            "--title=TaaOS'a Hoş Geldiniz!",
            "--text=<b>Hoş Geldin Mühendis!</b>\n\n<i>TaaOS - Professional Linux for Engineers</i>",
            "--width=400",
            "--ok-label=Tamam"
        ])
    except FileNotFoundError:
        pass
    # Mark as done even if fallback
    os.makedirs(os.path.dirname(FLAG_FILE), exist_ok=True)
    with open(FLAG_FILE, "w") as f:
        f.write("done")
    sys.exit(0)

# Mark as done before showing (prevent repeated failures from blocking)
os.makedirs(os.path.dirname(FLAG_FILE), exist_ok=True)
with open(FLAG_FILE, "w") as f:
    f.write("done")

class WelcomeScreen:
    def __init__(self, root):
        self.root = root
        self.root.title("TaaOS Welcome")
        self.root.attributes("-fullscreen", True)
        self.root.configure(bg="black")
        self.root.attributes("-topmost", True)
        self.root.config(cursor="none")
        
        # Start completely transparent
        try:
            self.root.attributes("-alpha", 0.0)
        except Exception:
            pass
        
        self.label = tk.Label(root, text="", font=("Helvetica", 54), fg="white", bg="black")
        self.label.pack(expand=True)
        
        # Subtitle
        self.sub_label = tk.Label(root, text="TaaOS - Engineer Edition", font=("Helvetica", 18), fg="#666666", bg="black")
        self.sub_label.pack(side="bottom", pady=50)
        
        self.greetings = [
            ("Hoş Geldin Mühendis", 1.8),
            ("Welcome Engineer", 1.5),
            ("Bienvenido Ingeniero", 1.2),
            ("Bienvenue Ingénieur", 1.2),
            ("Willkommen Ingenieur", 1.2),
            ("エンジニア ようこそ", 1.8)
        ]
        
        self.current_idx = 0
        self.root.after(500, self.cycle_greetings)
        
        # Click or key to skip
        self.root.bind("<Any-KeyPress>", self.close)
        self.root.bind("<Any-Button>", self.close)
        
    def fade_in(self, text):
        self.label.config(text=text)
        for i in range(0, 101, 4):
            try:
                self.root.attributes("-alpha", i / 100.0)
                self.root.update()
            except Exception:
                return
            time.sleep(0.008)

    def fade_out(self):
        for i in range(100, -1, -4):
            try:
                self.root.attributes("-alpha", i / 100.0)
                self.root.update()
            except Exception:
                return
            time.sleep(0.008)

    def cycle_greetings(self):
        if self.current_idx < len(self.greetings):
            text, duration = self.greetings[self.current_idx]
            self.fade_in(text)
            self.root.after(int(duration * 1000), self.prepare_next)
        else:
            self.close()
            
    def prepare_next(self):
        self.fade_out()
        self.current_idx += 1
        self.root.after(200, self.cycle_greetings)

    def close(self, event=None):
        try:
            self.root.destroy()
        except Exception:
            pass

if __name__ == "__main__":
    try:
        root = tk.Tk()
        root.withdraw()  # Hide initially
        root.deiconify()  # Then show (prevents flash)
        app = WelcomeScreen(root)
        root.mainloop()
    except Exception as e:
        # Log error for debugging instead of silently failing
        try:
            log_dir = os.path.expanduser("~/.config")
            os.makedirs(log_dir, exist_ok=True)
            with open(os.path.join(log_dir, "taaos-welcome-error.log"), "w") as f:
                f.write(f"Welcome screen error: {e}\n")
                import traceback
                traceback.print_exc(file=f)
        except Exception:
            pass
