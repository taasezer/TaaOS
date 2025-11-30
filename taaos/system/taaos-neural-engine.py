#!/usr/bin/env python3
"""
TaaOS Neural Engine - Enhanced Version
Advanced AI coordination with multi-model support and RAG
"""

import socket
import json
import threading
import subprocess
import requests
import time
import os
from pathlib import Path
from typing import Dict, List, Optional

class NeuralEngine:
    """TaaOS Neural Engine - Central AI Coordinator"""
    
    def __init__(self):
        self.host = 'localhost'
        self.port = 9999
        self.socket = None
        self.running = False
        
        # AI Models
        self.models = {
            'taaos-expert': 'llama3:latest',
            'code-assistant': 'codellama:latest',
            'vision': 'llava:latest'
        }
        
        # System context
        self.context = {
            'user_activity': 'idle',
            'system_load': 0.0,
            'active_app': None,
            'ai_mode': 'standard'
        }
        
        # RAG database
        self.knowledge_base = self.load_knowledge_base()
        
    def load_knowledge_base(self) -> Dict:
        """Load TaaOS documentation for RAG"""
        kb = {
            'system': [],
            'commands': [],
            'troubleshooting': []
        }
        
        docs_dir = Path('/usr/share/doc/taaos')
        if docs_dir.exists():
            for doc_file in docs_dir.glob('*.md'):
                with open(doc_file, 'r') as f:
                    content = f.read()
                    kb['system'].append({
                        'file': doc_file.name,
                        'content': content
                    })
        
        return kb
    
    def start(self):
        """Start Neural Engine server"""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.bind((self.host, self.port))
        self.socket.listen(5)
        self.running = True
        
        print(f"[Neural Engine] Started on {self.host}:{self.port}")
        print("[Neural Engine] Loading AI models...")
        
        # Ensure models are available
        self.ensure_models()
        
        # Start background tasks
        threading.Thread(target=self.monitor_system, daemon=True).start()
        threading.Thread(target=self.optimize_performance, daemon=True).start()
        
        # Accept connections
        while self.running:
            try:
                client, addr = self.socket.accept()
                threading.Thread(target=self.handle_client, args=(client,), daemon=True).start()
            except Exception as e:
                print(f"[Neural Engine] Error: {e}")
    
    def ensure_models(self):
        """Ensure all AI models are pulled"""
        for name, model in self.models.items():
            try:
                result = subprocess.run(
                    ['ollama', 'list'],
                    capture_output=True,
                    text=True
                )
                if model not in result.stdout:
                    print(f"[Neural Engine] Pulling {name} ({model})...")
                    subprocess.run(['ollama', 'pull', model])
            except Exception as e:
                print(f"[Neural Engine] Error loading {name}: {e}")
    
    def handle_client(self, client: socket.socket):
        """Handle client connection"""
        try:
            data = client.recv(4096).decode('utf-8')
            request = json.loads(data)
            
            response = self.process_request(request)
            
            client.send(json.dumps(response).encode('utf-8'))
        except Exception as e:
            error_response = {'error': str(e)}
            client.send(json.dumps(error_response).encode('utf-8'))
        finally:
            client.close()
    
    def process_request(self, request: Dict) -> Dict:
        """Process AI request"""
        req_type = request.get('type')
        
        if req_type == 'voice_command':
            return self.handle_voice_command(request)
        elif req_type == 'code_assist':
            return self.handle_code_assist(request)
        elif req_type == 'system_query':
            return self.handle_system_query(request)
        elif req_type == 'vision':
            return self.handle_vision(request)
        else:
            return {'error': 'Unknown request type'}
    
    def handle_voice_command(self, request: Dict) -> Dict:
        """Handle voice command with context awareness"""
        command = request.get('command', '')
        
        # Build context-aware prompt
        prompt = f"""You are TaaOS AI Assistant. Current context:
- User Activity: {self.context['user_activity']}
- Active App: {self.context['active_app']}
- System Load: {self.context['system_load']}%

User command: {command}

Provide a concise, actionable response. If it's a system command, provide the exact command to execute."""
        
        response = self.query_llm('taaos-expert', prompt)
        
        # Extract command if present
        if 'COMMAND:' in response:
            cmd = response.split('COMMAND:')[1].strip().split('\n')[0]
            return {
                'response': response,
                'command': cmd,
                'execute': True
            }
        
        return {'response': response}
    
    def handle_code_assist(self, request: Dict) -> Dict:
        """Handle code assistance request"""
        code = request.get('code', '')
        language = request.get('language', 'python')
        task = request.get('task', 'explain')
        
        prompt = f"""Language: {language}
Task: {task}

Code:
```{language}
{code}
```

Provide expert assistance."""
        
        response = self.query_llm('code-assistant', prompt)
        
        return {'response': response}
    
    def handle_system_query(self, request: Dict) -> Dict:
        """Handle system query with RAG"""
        query = request.get('query', '')
        
        # Search knowledge base
        relevant_docs = self.search_knowledge_base(query)
        
        # Build RAG prompt
        context = "\n\n".join([doc['content'][:500] for doc in relevant_docs[:3]])
        
        prompt = f"""Based on TaaOS documentation:

{context}

User question: {query}

Provide an accurate answer based on the documentation."""
        
        response = self.query_llm('taaos-expert', prompt)
        
        return {
            'response': response,
            'sources': [doc['file'] for doc in relevant_docs[:3]]
        }
    
    def handle_vision(self, request: Dict) -> Dict:
        """Handle vision/image analysis"""
        image_path = request.get('image_path', '')
        question = request.get('question', 'Describe this image')
        
        # Use LLaVA for vision tasks
        response = self.query_llm('vision', question, image=image_path)
        
        return {'response': response}
    
    def query_llm(self, model_name: str, prompt: str, image: Optional[str] = None) -> str:
        """Query Ollama LLM"""
        try:
            model = self.models.get(model_name, 'llama3:latest')
            
            payload = {
                'model': model,
                'prompt': prompt,
                'stream': False
            }
            
            if image:
                payload['images'] = [image]
            
            response = requests.post(
                'http://localhost:11434/api/generate',
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()['response']
            else:
                return f"Error: {response.status_code}"
        except Exception as e:
            return f"Error querying LLM: {e}"
    
    def search_knowledge_base(self, query: str) -> List[Dict]:
        """Simple keyword-based search in knowledge base"""
        results = []
        query_lower = query.lower()
        
        for category, docs in self.knowledge_base.items():
            for doc in docs:
                if query_lower in doc['content'].lower():
                    results.append(doc)
        
        return results
    
    def monitor_system(self):
        """Monitor system state"""
        while self.running:
            try:
                # Get system load
                with open('/proc/loadavg', 'r') as f:
                    load = float(f.read().split()[0])
                    self.context['system_load'] = load * 100
                
                # Get active window (simplified)
                try:
                    result = subprocess.run(
                        ['xdotool', 'getactivewindow', 'getwindowname'],
                        capture_output=True,
                        text=True
                    )
                    self.context['active_app'] = result.stdout.strip()
                except:
                    pass
                
                time.sleep(5)
            except Exception as e:
                print(f"[Monitor] Error: {e}")
                time.sleep(5)
    
    def optimize_performance(self):
        """AI-driven performance optimization"""
        while self.running:
            try:
                # Check if AI processes need priority boost
                result = subprocess.run(
                    ['pgrep', '-f', 'ollama|taaos|python'],
                    capture_output=True,
                    text=True
                )
                
                for pid in result.stdout.strip().split('\n'):
                    if pid:
                        try:
                            subprocess.run(['renice', '-n', '-10', '-p', pid])
                        except:
                            pass
                
                time.sleep(60)
            except Exception as e:
                print(f"[Optimizer] Error: {e}")
                time.sleep(60)
    
    def stop(self):
        """Stop Neural Engine"""
        self.running = False
        if self.socket:
            self.socket.close()

if __name__ == '__main__':
    engine = NeuralEngine()
    try:
        engine.start()
    except KeyboardInterrupt:
        print("\n[Neural Engine] Shutting down...")
        engine.stop()
