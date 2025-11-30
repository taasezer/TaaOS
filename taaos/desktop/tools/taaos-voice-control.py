#!/usr/bin/env python3
"""
TaaOS Voice Control (Jarvis-style)
Listens for wake word "Hey TaaOS" and sends commands to Neural Engine.
"""

import sys
import json
import socket
import speech_recognition as sr
import pyttsx3
import threading

# Configuration
WAKE_WORD = "taaos"
NEURAL_HOST = '127.0.0.1'
NEURAL_PORT = 5555

class VoiceAssistant:
    def __init__(self):
        self.recognizer = sr.Recognizer()
        self.engine = pyttsx3.init()
        self.setup_voice()
        
    def setup_voice(self):
        voices = self.engine.getProperty('voices')
        # Try to find a good English or Turkish voice
        self.engine.setProperty('rate', 170)
        
    def speak(self, text):
        print(f"🗣️ TaaOS: {text}")
        self.engine.say(text)
        self.engine.runAndWait()

    def send_to_neural_engine(self, text):
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.connect((NEURAL_HOST, NEURAL_PORT))
            
            payload = {
                "source": "voice",
                "content": text
            }
            
            client.send(json.dumps(payload).encode('utf-8'))
            response = json.loads(client.recv(4096).decode('utf-8'))
            
            if 'tts' in response:
                self.speak(response['tts'])
                
        except Exception as e:
            print(f"Error connecting to Neural Engine: {e}")
            self.speak("I seem to have lost connection to my neural core.")

    def listen_loop(self):
        print("🎤 TaaOS Voice Listening... (Say 'TaaOS')")
        with sr.Microphone() as source:
            self.recognizer.adjust_for_ambient_noise(source)
            
            while True:
                try:
                    audio = self.recognizer.listen(source, timeout=5)
                    text = self.recognizer.recognize_google(audio).lower()
                    
                    if WAKE_WORD in text:
                        self.speak("Yes?")
                        # Listen for command
                        audio_cmd = self.recognizer.listen(source, timeout=5)
                        cmd_text = self.recognizer.recognize_google(audio_cmd)
                        
                        print(f"User: {cmd_text}")
                        self.send_to_neural_engine(cmd_text)
                        
                except sr.WaitTimeoutError:
                    pass
                except sr.UnknownValueError:
                    pass
                except Exception as e:
                    print(f"Error: {e}")

if __name__ == '__main__':
    assistant = VoiceAssistant()
    assistant.listen_loop()
