import streamlit as st
import paho.mqtt.client as mqtt
import time

# Cấu hình MQTT
BROKER = "192.168.164.228"
PORT = 1883
TOPIC = "/test/topic1"

# Trạng thái đèn (Lưu trữ trong session)
if "is_led_on" not in st.session_state:
    st.session_state.is_led_on = False

# Hàm xử lý tin nhắn MQTT nhận được
def _on_message(client, userdata, msg):
    payload = msg.payload.decode("utf-8").strip()
    st.write(f"📥 Nhận dữ liệu từ MQTT: {payload}")  # Hiển thị log trên giao diện
    st.session_state.is_led_on = payload == "1"
    st.rerun()  # Cập nhật lại giao diện ngay khi nhận trạng thái mới

# Hàm kết nối MQTT và lắng nghe topic
def connect_mqtt():
    client = mqtt.Client()
    client.on_message = _on_message
    client.connect(BROKER, PORT, 60)
    client.subscribe(TOPIC)
    client.loop_start()  # Chạy lắng nghe MQTT song song
    return client

# Hàm gửi tín hiệu MQTT
def send_mqtt_message(payload):
    try:
        client = mqtt.Client()
        client.connect(BROKER, PORT, 60)
        client.publish(TOPIC, payload)
        client.disconnect()
        st.session_state.is_led_on = payload == "1"
        st.success(f"📢 Đã gửi tín hiệu: {'Bật' if payload == '1' else 'Tắt'}")
        st.rerun()  # Cập nhật giao diện ngay khi gửi lệnh
    except Exception as e:
        st.error(f"⚠️ Lỗi MQTT: {e}")

# Khởi động MQTT lắng nghe trạng thái đèn
mqtt_client = connect_mqtt()
time.sleep(1)  # Đợi MQTT kết nối xong trước khi cập nhật giao diện

# Giao diện Streamlit
st.title("🔌 Điều khiển Đèn MQTT")
st.subheader("Nhấn nút để bật/tắt đèn qua MQTT")

# Vùng hiển thị trạng thái và nút điều khiển
button_placeholder = st.empty()  # Giữ chỗ cho nút, sẽ cập nhật sau

# Cập nhật nút bật/tắt theo trạng thái mới nhất
if button_placeholder.button("Bật" if not st.session_state.is_led_on else "Tắt"):
    send_mqtt_message("1" if not st.session_state.is_led_on else "0")

# Hiển thị trạng thái hiện tại của đèn
st.markdown(f"### {'🟢' if st.session_state.is_led_on else '🔴'} Đèn đang **{'BẬT' if st.session_state.is_led_on else 'TẮT'}**")
