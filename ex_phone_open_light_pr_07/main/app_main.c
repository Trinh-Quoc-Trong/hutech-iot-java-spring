#include <stdio.h>  
#include <stdint.h>  
#include <stddef.h>  
#include <string.h>  
#include "esp_wifi.h"  
#include "esp_system.h"  
#include "nvs_flash.h"  
#include "esp_event.h"  
#include "esp_netif.h"  
#include "protocol_examples_common.h"  

#include "freertos/FreeRTOS.h"  
#include "freertos/task.h"  
#include "freertos/semphr.h"  
#include "freertos/queue.h"  

#include "lwip/sockets.h"  
#include "lwip/dns.h"  
#include "lwip/netdb.h"  

#include "esp_log.h"  
#include "mqtt_client.h"  
#include "driver/gpio.h"  
#include "D:/code/projects/Hutech_IOT/ex_phone_open_light_pr_07/QRCode/src/qrcode.h" // Thêm thư viện QRCode  
#include "D:/code/projects/Hutech_IOT/ex_phone_open_light_pr_07/QRCode/src/qrcode.c" // Thêm thư viện QRCode  

static const char *TAG = "MQTT_LED";  
#define ESP_WIFI_SSID "Wifi 6 Pro Max"  
#define ESP_WIFI_PASS "mangiuqua"  
#define ESP_BROKER_IP "mqtt://192.168.100.40:1883"  
#define LED_GPIO GPIO_NUM_48 // Chân GPIO để điều khiển LED  

static uint8_t LED_STATE = 0;  
static esp_mqtt_client_handle_t client = NULL;  

static void mqtt_app_start(void);  

// Hàm in mã QR  
void print_qr_code(const char *data) {  
    QRCode qrcode;  
    uint8_t qrcodeData[qrcode_getBufferSize(3)];  
    qrcode_initText(&qrcode, qrcodeData, 3, 0, data);  

    for (uint8_t y = 0; y < qrcode.size; y++) {  
        for (uint8_t x = 0; x < qrcode.size; x++) {  
            printf("%s", qrcode_getModule(&qrcode, x, y) ? "##" : "  ");  
        }  
        printf("\n");  
    }  
}  

static void wifi_event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data) {  
    if (event_base == WIFI_EVENT) {  
        switch (event_id) {  
            case WIFI_EVENT_STA_START:  
                esp_wifi_connect();  
                ESP_LOGI(TAG, "Connecting to Wi-Fi");  
                break;  
            case WIFI_EVENT_STA_DISCONNECTED:  
                ESP_LOGI(TAG, "Wi-Fi disconnected, retrying...");  
                esp_wifi_connect();  
                break;  
            default:  
                break;  
        }  
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {  
        ESP_LOGI(TAG, "Wi-Fi connected, starting MQTT...");  
        mqtt_app_start();  

        // In mã QR sau khi kết nối WiFi thành công  
        const char *qr_data = "mqtt://192.168.100.40:1883,/test/topic1";  
        print_qr_code(qr_data);  
    }  
}  

void wifi_init(void) {  
    ESP_ERROR_CHECK(esp_netif_init());  
    ESP_ERROR_CHECK(esp_event_loop_create_default());  
    esp_netif_create_default_wifi_sta();  

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();  
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));  

    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL, NULL));  
    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL, NULL));  

    wifi_config_t wifi_config = {  
        .sta = {  
            .ssid = ESP_WIFI_SSID,  
            .password = ESP_WIFI_PASS,  
            .threshold.authmode = WIFI_AUTH_WPA2_PSK,  
        },  
    };  
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));  
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));  
    ESP_ERROR_CHECK(esp_wifi_start());  
}  

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {  
    esp_mqtt_event_handle_t event = event_data;  
    esp_mqtt_client_handle_t client = event->client;  

    switch ((esp_mqtt_event_id_t)event_id) {  
        case MQTT_EVENT_CONNECTED:  
            ESP_LOGI(TAG, "Connected to MQTT broker");  
            esp_mqtt_client_subscribe(client, "/test/topic1", 0);  
            break;  
        case MQTT_EVENT_DISCONNECTED:  
            ESP_LOGI(TAG, "Disconnected from MQTT broker");  
            break;  
        case MQTT_EVENT_DATA:  
            ESP_LOGI(TAG, "Received MQTT message");  
            printf("TOPIC=%.*s\r\n", event->topic_len, event->topic);  
            printf("DATA=%.*s\r\n", event->data_len, event->data);  

            // Loại bỏ điều kiện kiểm tra trạng thái LED hiện tại  
            if (strncmp(event->data, "1", event->data_len) == 0) {  
                gpio_set_level(LED_GPIO, 1);  
                LED_STATE = 1;  
                ESP_LOGI(TAG, "LED turned ON");  
            } else if (strncmp(event->data, "0", event->data_len) == 0) {  
                gpio_set_level(LED_GPIO, 0);  
                LED_STATE = 0;  
                ESP_LOGI(TAG, "LED turned OFF");  
            }  
            break;  
        default:  
            // Sử dụng %ld cho int32_t hoặc ép kiểu về int  
            ESP_LOGI(TAG, "Unhandled MQTT event: %ld", (long)event_id);  
            break;  
    }  
}  

static void mqtt_app_start(void) {  
    ESP_LOGI(TAG, "Starting MQTT client");  
    esp_mqtt_client_config_t mqtt_cfg = {  
        .broker.address.uri = ESP_BROKER_IP,  
    };  
    client = esp_mqtt_client_init(&mqtt_cfg);  
    esp_mqtt_client_register_event(client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);  
    esp_mqtt_client_start(client);  
}  

void app_main(void) {  
    esp_err_t ret = nvs_flash_init();  
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {  
        ESP_ERROR_CHECK(nvs_flash_erase());  
        ret = nvs_flash_init();  
    }  
    ESP_ERROR_CHECK(ret);  

    // Cấu hình đúng cho GPIO  
    gpio_reset_pin(LED_GPIO);  
    gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);  
    
    // Thay đổi từ GPIO_PULLDOWN_ONLY thành GPIO_FLOATING để tránh pull-down  
    gpio_set_pull_mode(LED_GPIO, GPIO_FLOATING);  
    
    // Thiết lập trạng thái ban đầu là tắt  
    gpio_set_level(LED_GPIO, 0);  
    LED_STATE = 0;  

    wifi_init();  
}  