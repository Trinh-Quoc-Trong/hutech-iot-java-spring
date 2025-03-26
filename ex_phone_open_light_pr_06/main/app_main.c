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
#include "D:/code/projects/Hutech_IOT/ex_phone_open_light_pr_06/QR-Code-generator/c/qrcodegen.h"  
#include "D:/code/projects/Hutech_IOT/ex_phone_open_light_pr_06/QR-Code-generator/c/qrcodegen.c"

static const char *TAG = "MQTT_LED";  
#define ESP_WIFI_SSID "Wifi 6 Pro Max"  
#define ESP_WIFI_PASS "mangiuqua"  
#define ESP_BROKER_IP "mqtt://192.168.100.40:1883"  
#define LED_GPIO GPIO_NUM_48 // Chân GPIO để điều khiển LED  

static uint8_t LED_STATE = 0;  
static esp_mqtt_client_handle_t client = NULL;  

// Khai báo hàm mqtt_app_start  
static void mqtt_app_start(void);  

// Hàm tạo và in mã QR  
void print_qr_code(const char *text) {  
    uint8_t qr0[qrcodegen_BUFFER_LEN_MAX];  
    uint8_t tempBuffer[qrcodegen_BUFFER_LEN_MAX];  
    bool ok = qrcodegen_encodeText(text, tempBuffer, qr0, qrcodegen_Ecc_LOW,  
                                   qrcodegen_VERSION_MIN, qrcodegen_VERSION_MAX, qrcodegen_Mask_AUTO, true);  
    if (!ok) {  
        ESP_LOGE(TAG, "Failed to generate QR code");  
        return;  
    }  

    int size = qrcodegen_getSize(qr0);  
    for (int y = 0; y < size; y++) {  
        for (int x = 0; x < size; x++) {  
            printf("%s", qrcodegen_getModule(qr0, x, y) ? "##" : "  ");  
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

// void app_main(void) {  
//     esp_err_t ret = nvs_flash_init();  
//     if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {  
//         ESP_ERROR_CHECK(nvs_flash_erase());  
//         ret = nvs_flash_init();  
//     }  
//     ESP_ERROR_CHECK(ret);  

//     gpio_reset_pin(LED_GPIO);  
//     gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);  
//     gpio_set_pull_mode(LED_GPIO, GPIO_FLOATING);  
//     gpio_set_level(LED_GPIO, 0);  
//     LED_STATE = 0;  

//     // Tạo và in mã QR chứa thông tin MQTT broker  
//     const char *mqtt_info = "mqtt://192.168.100.40:1883,/test/topic1";  
//     ESP_LOGI(TAG, "MQTT QR Code:");  
//     print_qr_code(mqtt_info);  

//     wifi_init();  
// }  


void app_main(void) {  
    // Xóa và khởi tạo lại NVS  
    // esp_err_t ret = nvs_flash_init();  
    // if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {  
    //     ESP_ERROR_CHECK(nvs_flash_erase());  
    //     ret = nvs_flash_init();  
    // }  
    // ESP_ERROR_CHECK(ret);  

    // Cấu hình GPIO cho LED  
    gpio_reset_pin(LED_GPIO);  
    gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);  
    gpio_set_pull_mode(LED_GPIO, GPIO_FLOATING);  
    gpio_set_level(LED_GPIO, 0);  
    LED_STATE = 0;  

    // Tạo và in mã QR chứa thông tin MQTT broker  
    const char *mqtt_info = "mqtt://192.168.100.40:1883,/test/topic1";  
    ESP_LOGI(TAG, "MQTT QR Code:");  
    print_qr_code(mqtt_info);  

    // Khởi tạo WiFi  
    wifi_init();  
}  