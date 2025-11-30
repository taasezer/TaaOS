#!/usr/bin/env python3
"""
TaaTheme API
Python API for TaaOS Theme Engine
"""

class TaaTheme:
    """TaaOS Theme Engine API"""
    
    THEMES = {
        'rosso-corsa': {
            'primary': '#D40000',
            'background': '#0A0A0A',
            'surface': '#1A1A1A',
            'text': '#F5F5F0'
        },
        'midnight-black': {
            'primary': '#000000',
            'background': '#0D0D0D',
            'surface': '#1A1A1A',
            'text': '#FFFFFF'
        },
        'arctic-blue': {
            'primary': '#00A8E8',
            'background': '#0A1929',
            'surface': '#1A2332',
            'text': '#E3F2FD'
        }
    }
    
    @staticmethod
    def get_theme(name):
        """Get theme colors by name"""
        return TaaTheme.THEMES.get(name, TaaTheme.THEMES['rosso-corsa'])
    
    @staticmethod
    def apply_theme(name):
        """Apply theme system-wide"""
        import subprocess
        subprocess.run(['taatheme', 'apply', name])
    
    @staticmethod
    def list_themes():
        """List available themes"""
        return list(TaaTheme.THEMES.keys())

if __name__ == '__main__':
    print("TaaTheme API v1.0")
    print("Available themes:", TaaTheme.list_themes())
