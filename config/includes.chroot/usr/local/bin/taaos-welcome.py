#!/usr/bin/env python3
# =============================================================================
# TaaOS Mac-Style First Boot Welcome Screen
# =============================================================================
import tkinter as tk
import time
import os
import sys

# Only run once per user
FLAG_FILE = os.path.expanduser("~/.config/taaos-welcome-done")

if os.path.exists(FLAG_FILE):
    sys.exit(0)

os.makedirs(os.path.dirname(FLAG_FILE), exist_ok=True)
with open(FLAG_FILE, "w") as f:
    f.write("done")

class WelcomeScreen:
    def __init__(self, root):
        self.root = root
        self.root.attributes("-fullscreen", True)
        self.root.configure(bg="black")
        self.root.attributes("-topmost", True)
        self.root.config(cursor="none")
        
        # Start completely transparent
        self.root.attributes("-alpha", 0.0)
        
        self.label = tk.Label(root, text="", font=("Helvetica", 54), fg="white", bg="black")
        self.label.pack(expand=True)
        
        # Subtitle for context (smaller font, soft appearance)
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
        self.root.after(1000, self.cycle_greetings)
        
        # Click or key to skip immediately
        self.root.bind("<Any-KeyPress>", self.close)
        self.root.bind("<Any-Button>", self.close)
        
    def fade_in(self, text):
        self.label.config(text=text)
        # 60 FPS smooth fade-in
        for i in range(0, 101, 2):
            self.root.attributes("-alpha", i / 100.0)
            self.root.update()
            time.sleep(0.005)

    def fade_out(self):
        # 60 FPS smooth fade-out
        for i in range(100, -1, -2):
            self.root.attributes("-alpha", i / 100.0)
            self.root.update()
            time.sleep(0.005)

    def cycle_greetings(self):
        if self.current_idx < len(self.greetings):
            text, duration = self.greetings[self.current_idx]
            self.fade_in(text)
            
            # Wait for duration, then fade out
            self.root.after(int(duration * 1000), self.prepare_next)
        else:
            self.close()
            
    def prepare_next(self):
        self.fade_out()
        self.current_idx += 1
        self.root.after(200, self.cycle_greetings)

    def close(self, event=None):
        self.root.destroy()

if __name__ == "__main__":
    try:
        root = tk.Tk()
        app = WelcomeScreen(root)
        root.mainloop()
    except Exception:
        # Failsafe: if Tkinter fails (e.g., no display), just exit gracefully
        pass
