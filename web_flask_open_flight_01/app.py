from flask import Flask, render_template, request, jsonify  
from flask_socketio import SocketIO  
import paho.mqtt.client as mqtt  
import threading  

app = Flask(__name__)  

if __name__ == '__main__':  
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)  