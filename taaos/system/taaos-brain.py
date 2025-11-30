#!/usr/bin/env python3
"""
TaaOS Brain - Enhanced Version
Predictive system optimization with machine learning
"""

import subprocess
import requests
import json
import time
import os
from datetime import datetime
from collections import deque
import statistics

class TaaOSBrain:
    """Enhanced TaaOS Brain with predictive analytics"""
    
    def __init__(self):
        self.ollama_url = "http://localhost:11434/api/generate"
        self.n8n_webhook = "http://localhost:5678/webhook/taaos-alert"
        self.neural_engine = ("localhost", 9999)
        
        # Historical data for predictions
        self.cpu_history = deque(maxlen=100)
        self.memory_history = deque(maxlen=100)
        self.disk_history = deque(maxlen=100)
        
        # AI model
        self.model = "llama3:latest"
        
        # Learning mode
        self.learning_enabled = True
        self.patterns = self.load_patterns()
        
    def load_patterns(self):
        """Load learned patterns from disk"""
        pattern_file = "/var/lib/taaos/brain_patterns.json"
        if os.path.exists(pattern_file):
            with open(pattern_file, 'r') as f:
                return json.load(f)
        return {
            'cpu_spikes': [],
            'memory_leaks': [],
            'disk_issues': [],
            'network_problems': []
        }
    
    def save_patterns(self):
        """Save learned patterns to disk"""
        pattern_file = "/var/lib/taaos/brain_patterns.json"
        os.makedirs(os.path.dirname(pattern_file), exist_ok=True)
        with open(pattern_file, 'w') as f:
            json.dump(self.patterns, f, indent=2)
    
    def analyze_system(self):
        """Comprehensive system analysis with predictions"""
        print("[Brain] Analyzing system state...")
        
        # Collect metrics
        cpu_usage = self.get_cpu_usage()
        memory_usage = self.get_memory_usage()
        disk_usage = self.get_disk_usage()
        
        # Store in history
        self.cpu_history.append(cpu_usage)
        self.memory_history.append(memory_usage)
        self.disk_history.append(disk_usage)
        
        # Predictive analysis
        predictions = self.predict_issues()
        
        # Check for anomalies
        issues = []
        
        if cpu_usage > 80:
            issues.append(f"High CPU usage: {cpu_usage}%")
            self.learn_pattern('cpu_spikes', {
                'timestamp': datetime.now().isoformat(),
                'value': cpu_usage,
                'processes': self.get_top_processes()
            })
        
        if memory_usage > 85:
            issues.append(f"High memory usage: {memory_usage}%")
            self.learn_pattern('memory_leaks', {
                'timestamp': datetime.now().isoformat(),
                'value': memory_usage
            })
        
        if disk_usage > 90:
            issues.append(f"Low disk space: {disk_usage}% used")
            self.learn_pattern('disk_issues', {
                'timestamp': datetime.now().isoformat(),
                'value': disk_usage
            })
        
        # Check predictions
        for prediction in predictions:
            issues.append(f"PREDICTION: {prediction}")
        
        if issues:
            self.handle_issues(issues)
        
        # Log to Guardian
        self.log_to_guardian(cpu_usage, memory_usage, disk_usage, issues)
    
    def predict_issues(self):
        """Predict future issues based on historical data"""
        predictions = []
        
        # CPU trend analysis
        if len(self.cpu_history) >= 10:
            recent_cpu = list(self.cpu_history)[-10:]
            cpu_trend = statistics.mean(recent_cpu[-5:]) - statistics.mean(recent_cpu[:5])
            
            if cpu_trend > 10:
                predictions.append("CPU usage trending upward - potential spike in 5-10 minutes")
        
        # Memory leak detection
        if len(self.memory_history) >= 20:
            recent_mem = list(self.memory_history)[-20:]
            mem_trend = statistics.mean(recent_mem[-10:]) - statistics.mean(recent_mem[:10])
            
            if mem_trend > 5:
                predictions.append("Memory usage steadily increasing - possible memory leak")
        
        # Pattern-based predictions
        if len(self.patterns['cpu_spikes']) > 5:
            # Check if similar pattern exists
            current_hour = datetime.now().hour
            spike_hours = [datetime.fromisoformat(p['timestamp']).hour 
                          for p in self.patterns['cpu_spikes'][-10:]]
            
            if spike_hours.count(current_hour) >= 3:
                predictions.append(f"Historical pattern: CPU spikes common at {current_hour}:00")
        
        return predictions
    
    def learn_pattern(self, pattern_type, data):
        """Learn from system patterns"""
        if not self.learning_enabled:
            return
        
        self.patterns[pattern_type].append(data)
        
        # Keep only recent patterns (last 100)
        if len(self.patterns[pattern_type]) > 100:
            self.patterns[pattern_type] = self.patterns[pattern_type][-100:]
        
        # Save periodically
        if sum(len(p) for p in self.patterns.values()) % 10 == 0:
            self.save_patterns()
    
    def handle_issues(self, issues):
        """Handle detected issues with AI-powered solutions"""
        print(f"[Brain] Issues detected: {len(issues)}")
        
        # Build AI prompt
        prompt = f"""You are TaaOS Brain, an AI system optimizer. Analyze these system issues and provide solutions:

Issues:
{chr(10).join(f'- {issue}' for issue in issues)}

Provide:
1. Root cause analysis
2. Immediate actions (shell commands)
3. Long-term recommendations

Format: 
ANALYSIS: <analysis>
COMMANDS: <commands>
RECOMMENDATIONS: <recommendations>
"""
        
        # Query AI
        try:
            response = requests.post(
                self.ollama_url,
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=30
            )
            
            if response.status_code == 200:
                ai_response = response.json()['response']
                print(f"[Brain] AI Analysis:\n{ai_response}")
                
                # Extract and execute commands
                if "COMMANDS:" in ai_response:
                    commands = ai_response.split("COMMANDS:")[1].split("RECOMMENDATIONS:")[0].strip()
                    self.execute_remediation(commands)
                
                # Trigger n8n workflow
                self.trigger_n8n_workflow({
                    'issues': issues,
                    'ai_analysis': ai_response,
                    'timestamp': datetime.now().isoformat()
                })
        
        except Exception as e:
            print(f"[Brain] Error querying AI: {e}")
    
    def execute_remediation(self, commands):
        """Execute remediation commands safely"""
        print("[Brain] Executing remediation...")
        
        # Parse commands (simple implementation)
        for line in commands.split('\n'):
            line = line.strip()
            if line.startswith('sudo') or line.startswith('rm'):
                print(f"[Brain] Skipping dangerous command: {line}")
                continue
            
            if line and not line.startswith('#'):
                try:
                    print(f"[Brain] Executing: {line}")
                    subprocess.run(line, shell=True, timeout=10)
                except Exception as e:
                    print(f"[Brain] Command failed: {e}")
    
    def get_cpu_usage(self):
        """Get current CPU usage"""
        try:
            with open('/proc/loadavg', 'r') as f:
                load = float(f.read().split()[0])
                return min(load * 25, 100)  # Rough conversion
        except:
            return 0
    
    def get_memory_usage(self):
        """Get current memory usage"""
        try:
            with open('/proc/meminfo', 'r') as f:
                lines = f.readlines()
                total = int([l for l in lines if 'MemTotal' in l][0].split()[1])
                available = int([l for l in lines if 'MemAvailable' in l][0].split()[1])
                used = total - available
                return (used / total) * 100
        except:
            return 0
    
    def get_disk_usage(self):
        """Get current disk usage"""
        try:
            result = subprocess.run(
                ['df', '-h', '/'],
                capture_output=True,
                text=True
            )
            usage = result.stdout.split('\n')[1].split()[4].replace('%', '')
            return float(usage)
        except:
            return 0
    
    def get_top_processes(self):
        """Get top CPU-consuming processes"""
        try:
            result = subprocess.run(
                ['ps', 'aux', '--sort=-%cpu'],
                capture_output=True,
                text=True
            )
            lines = result.stdout.split('\n')[1:6]  # Top 5
            return [' '.join(line.split()[10:]) for line in lines if line]
        except:
            return []
    
    def log_to_guardian(self, cpu, memory, disk, issues):
        """Log to TaaOS Guardian"""
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'cpu': cpu,
            'memory': memory,
            'disk': disk,
            'issues': issues
        }
        
        log_file = "/var/log/taaos/brain.log"
        os.makedirs(os.path.dirname(log_file), exist_ok=True)
        
        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
    
    def trigger_n8n_workflow(self, data):
        """Trigger n8n automation workflow"""
        try:
            requests.post(self.n8n_webhook, json=data, timeout=5)
        except:
            pass
    
    def run(self):
        """Main loop"""
        print("[Brain] TaaOS Brain started - Enhanced with ML predictions")
        print("[Brain] Learning mode:", "ENABLED" if self.learning_enabled else "DISABLED")
        
        while True:
            try:
                self.analyze_system()
                time.sleep(60)  # Check every minute
            except KeyboardInterrupt:
                print("\n[Brain] Shutting down...")
                self.save_patterns()
                break
            except Exception as e:
                print(f"[Brain] Error: {e}")
                time.sleep(60)

if __name__ == '__main__':
    brain = TaaOSBrain()
    brain.run()
