import eventlet
eventlet.monkey_patch()

from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit
import paho.mqtt.client as mqtt
import json # Import json để xử lý dictionary trong template

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, async_mode='eventlet')

# Cấu hình MQTT
mqtt_broker = "192.168.100.40"
mqtt_port = 1883
# Danh sách các topic cần quản lý
mqtt_topics = ["/test/topic1", "/test/topic2"]

# Sử dụng dictionary để lưu trạng thái của từng đèn, key là topic
light_states = {topic: "unknown" for topic in mqtt_topics}

# Định nghĩa tên thân thiện cho từng topic (tùy chọn)
device_names = {
    "/test/topic1": "Đèn phòng khách",
    "/test/topic2": "Đèn nhà bếp"
}

mqtt_client = mqtt.Client()

# Callback khi kết nối MQTT thành công
def on_connect(client, userdata, flags, rc):
    print(f"Đã kết nối tới MQTT Broker với mã kết quả: {rc}")
    if rc == 0:
        for topic in mqtt_topics:
            client.subscribe(topic)
            print(f"Đã đăng ký topic: {topic}")
    else:
        print("Kết nối MQTT thất bại!")

# Callback khi nhận được tin nhắn MQTT
def on_message(client, userdata, msg):
    global light_states
    payload = msg.payload.decode("utf-8")
    topic = msg.topic
    print(f"Nhận được tin nhắn từ topic {topic}: {payload}")

    if topic in light_states:
        new_state = "unknown"
        if payload == "1":
            new_state = "ON"
        elif payload == "0":
            new_state = "OFF"

        if light_states[topic] != new_state:
            light_states[topic] = new_state
            # Gửi trạng thái của TẤT CẢ các đèn tới client khi có thay đổi
            socketio.emit('update_state', {'states': light_states})
            print(f"Đã cập nhật trạng thái đèn [{topic}] trên web: {new_state}")
    else:
        print(f"Nhận được tin nhắn từ topic không được quản lý: {topic}")


mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message

def mqtt_connect():
    while True: # Thêm vòng lặp để thử kết nối lại
        try:
            print(f"Đang kết nối tới MQTT Broker: {mqtt_broker}:{mqtt_port}...")
            mqtt_client.connect(mqtt_broker, mqtt_port, 60)
            mqtt_client.loop_forever() # Chặn và lắng nghe
        except Exception as e:
            print(f"Lỗi kết nối MQTT hoặc loop bị gián đoạn: {e}")
            print("Thử kết nối lại sau 5 giây...")
            mqtt_client.disconnect() # Đảm bảo ngắt kết nối trước khi thử lại
            eventlet.sleep(5)

# Chạy MQTT client trong một greenlet riêng biệt
eventlet.spawn(mqtt_connect)

@app.route('/')
def index():
    # ---- Tạm thời dùng dữ liệu tĩnh để test ----
    test_data = {
        'states': {"/test/topic1": "ON", "/test/topic2": "OFF"}, # Dữ liệu giả định
        'names': {"/test/topic1": "Đèn Test 1", "/test/topic2": "Đèn Test 2"} # Tên giả định
    }
    print(f"DEBUG Flask Route: Passing STATIC test_data to template: {test_data}")
    return render_template('index.html', initial_data=test_data) # Luôn truyền key là 'initial_data'
    # ---- Kết thúc phần test ----

    # # Code gốc (tạm thời comment lại):
    # initial_data = {
    #     'states': light_states,
    #     'names': device_names
    # }
    # print(f"DEBUG Flask Route: Passing initial_data to template: {initial_data}")
    # return render_template('index.html', initial_data=initial_data)

@socketio.on('publish_message')
def handle_publish(message):
    topic = message.get('topic')
    payload = message.get('payload')
    if topic in mqtt_topics:
        print(f"Gửi tin nhắn MQTT tới topic {topic}: {payload}")
        mqtt_client.publish(topic, payload)
    else:
        print(f"Yêu cầu publish tới topic không hợp lệ: {topic}")

@socketio.on('request_initial_state') # Thêm xử lý yêu cầu trạng thái
def handle_request_initial_state():
    print("Client yêu cầu trạng thái ban đầu.")
    emit('update_state', {'states': light_states, 'names': device_names})

# Xử lý thêm thiết bị mới
@socketio.on('add_device')
def handle_add_device(data):
    topic = data.get('topic')
    name = data.get('name')

    response = {
        'success': False,
        'message': 'Lỗi không xác định'
    }

    if not topic:
        response['message'] = "Topic không được để trống!"
        emit('update_state', {'states': light_states, 'names': device_names, **response})
        return

    # Đơn giản hóa: loại bỏ khoảng trắng và kiểm tra cơ bản
    topic = topic.strip()
    if not topic.startswith('/'):
         topic = '/' + topic # Tự thêm dấu / nếu thiếu

    if topic in light_states:
        response['message'] = f"Thiết bị với topic '{topic}' đã tồn tại!"
        emit('update_state', {'states': light_states, 'names': device_names, **response})
        return

    try:
        print(f"Thêm thiết bị mới: Topic='{topic}', Name='{name or '(mặc định)'}'")
        # Thêm vào danh sách quản lý
        mqtt_topics.append(topic)
        light_states[topic] = 'unknown' # Trạng thái ban đầu
        device_names[topic] = name.strip() if name else topic # Dùng tên nếu có, không thì dùng topic

        # Đăng ký topic với MQTT client
        mqtt_client.subscribe(topic)
        print(f"Đã đăng ký topic mới: {topic}")

        response['success'] = True
        response['message'] = f"Đã thêm thiết bị '{device_names[topic]}' thành công!"

        # Gửi trạng thái cập nhật và thông báo tới tất cả client
        socketio.emit('update_state', {'states': light_states, 'names': device_names, **response})

    except Exception as e:
        print(f"Lỗi khi thêm thiết bị '{topic}': {e}")
        response['message'] = f"Lỗi server khi thêm thiết bị: {e}"
         # Gửi lại trạng thái cũ và thông báo lỗi
        socketio.emit('update_state', {'states': light_states, 'names': device_names, **response})

@socketio.on('connect')
def handle_connect():
    print('Client đã kết nối qua SocketIO')
    # Gửi trạng thái hiện tại cho client vừa kết nối
    emit('update_state', {'states': light_states})

@socketio.on('disconnect')
def handle_disconnect():
    print('Client đã ngắt kết nối SocketIO')

if __name__ == '__main__':
    print("Khởi chạy Flask server...")
    socketio.run(app, host='0.0.0.0', port=5000, debug=True, use_reloader=False) # Thêm use_reloader=False để tránh chạy mqtt_connect 2 lần khi debug=True 