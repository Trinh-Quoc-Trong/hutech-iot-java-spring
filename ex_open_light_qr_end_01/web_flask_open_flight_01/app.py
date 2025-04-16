from flask import Flask, render_template, request, jsonify, send_file
from flask_socketio import SocketIO
import paho.mqtt.client as mqtt
import threading
import qrcode
import io
import base64
import re
import os

app = Flask(__name__)
socketio = SocketIO(app)

def read_mqtt_config():
    try:
        # Lấy đường dẫn tuyệt đối của thư mục hiện tại
        current_dir = os.path.dirname(os.path.abspath(__file__))
        # Đường dẫn đến file app_main.c
        app_main_path = os.path.join(os.path.dirname(current_dir), 'main', 'app_main.c')
        
        # Mở file với encoding UTF-8
        with open(app_main_path, 'r', encoding='utf-8') as file:
            content = file.read()
            
            # Tìm ESP_BROKER_IP
            broker_match = re.search(r'#define ESP_BROKER_IP "([^"]+)"', content)
            broker = broker_match.group(1) if broker_match else "192.168.108.188"
            
            # Tìm topic
            topic_match = re.search(r'esp_mqtt_client_subscribe\(client, "([^"]+)", 0\)', content)
            topic = topic_match.group(1) if topic_match else "/test/topic1"
            
            # Tìm thông tin WiFi
            wifi_ssid_match = re.search(r'#define ESP_WIFI_SSID "([^"]+)"', content)
            wifi_ssid = wifi_ssid_match.group(1) if wifi_ssid_match else "Duc Chung"
            
            wifi_pass_match = re.search(r'#define ESP_WIFI_PASS "([^"]+)"', content)
            wifi_pass = wifi_pass_match.group(1) if wifi_pass_match else "11556886"
            
            # Tách port từ broker URL
            port = 1883 # Giá trị port mặc định
            broker_address = broker # Giữ lại địa chỉ gốc
            if '://' in broker_address:
                 # Loại bỏ phần protocol (ví dụ: 'mqtt://') để xử lý dễ hơn
                 address_part = broker_address.split('://')[1]
                 if ':' in address_part:
                     last_colon_index = address_part.rfind(':')
                     potential_port = address_part[last_colon_index+1:]
                     if potential_port.isdigit():
                         port = int(potential_port)
                         # Cập nhật lại broker address không bao gồm port
                         broker_address = broker_address[:broker_address.rfind(':')]
            if '://' in broker_address:
                # Đảm bảo chỉ lấy phần địa chỉ sau scheme
                broker_address = broker_address.split('://')[1]
            return {
                'broker': broker_address, # Trả về địa chỉ không có port
                'port': port,
                'topic': topic,
                'wifi_ssid': wifi_ssid,
                'wifi_pass': wifi_pass
            }
    except Exception as e:
        print(f"Lỗi khi đọc file cấu hình: {e}")
        return {
            'broker': "192.168.108.188",
            'port': 1883,
            'topic': "/test/topic1",
            'wifi_ssid': "Duc Chung",
            'wifi_pass': "11556886"
        }

def generate_qr():
    # Đọc cấu hình MQTT từ file
    config = read_mqtt_config()

    # Tạo nội dung cho mã QR *** <- Sửa dòng này ***
    qr_content = f"@mqtt://{config['broker']},{config['port']},{config['topic']}" # Thêm @mqtt://

    # Tạo mã QR
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_content)
    qr.make(fit=True)

    # Tạo ảnh QR
    img = qr.make_image(fill_color="black", back_color="white")

    # Chuyển đổi ảnh thành base64
    img_buffer = io.BytesIO()
    img.save(img_buffer, format='PNG')
    img_str = base64.b64encode(img_buffer.getvalue()).decode()

    return img_str, config

@app.route('/')
def index():
    qr_image, config = generate_qr()
    return render_template('index.html', 
                         qr_image=qr_image,
                         broker=config['broker'],
                         port=config['port'],
                         topic=config['topic'],
                         wifi_ssid=config['wifi_ssid'],
                         wifi_pass=config['wifi_pass'])

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)  