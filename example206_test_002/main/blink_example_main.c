#include <stdio.h>  
#include "freertos/FreeRTOS.h"  
#include "freertos/task.h"  
#include "driver/gpio.h"  
#include "esp_log.h"  
#include "sdkconfig.h"  

#define BLINK_GPIO GPIO_NUM_48 
#define TASK_STACK_SIZE 4096  
#define TASK_PRIORITY 10  

TaskHandle_t HelloWorldTaskHandle = NULL;  
TaskHandle_t BlinkyTaskHandle = NULL;  

void HelloWorld_Task(void *arg)  
{  
    for(;;) {  
        printf("Task running: Hello World..\n");  
        vTaskDelay(pdMS_TO_TICKS(1000));  
    }  
    vTaskDelete(NULL); // Tự xóa task nếu thoát vòng lặp  
}  

void Blinky_Task(void *arg)  
{  
    esp_rom_gpio_pad_select_gpio(BLINK_GPIO);  
    gpio_set_direction(BLINK_GPIO, GPIO_MODE_OUTPUT);  
    
    int count_second = 0;  
    while (1)  
    {  
        count_second++;  
        
        switch (count_second)  
        {  
        case 10:  
            if (HelloWorldTaskHandle != NULL) {  
                vTaskSuspend(HelloWorldTaskHandle);  
                printf("HelloWorld task suspended .. \n");  
            }  
            break;  
        case 14:  
            if (HelloWorldTaskHandle != NULL) {  
                vTaskResume(HelloWorldTaskHandle);  
                printf("HelloWorld task resumed .. \n");  
            }  
            break;  
        case 20:  
            if (HelloWorldTaskHandle != NULL) {  
                vTaskDelete(HelloWorldTaskHandle);  
                HelloWorldTaskHandle = NULL;  
                printf("HelloWorld task deleted .. \n");  
            }  
            break;  
        }  
        
        gpio_set_level(BLINK_GPIO, 1);  
        vTaskDelay(pdMS_TO_TICKS(1000));  
        gpio_set_level(BLINK_GPIO, 0);  
        vTaskDelay(pdMS_TO_TICKS(1000));  
    }  
}  

void app_main(void)  
{  
    BaseType_t xReturned;  
    
    xReturned = xTaskCreatePinnedToCore(  
        Blinky_Task,   
        "Blinky",   
        TASK_STACK_SIZE,   
        NULL,   
        TASK_PRIORITY,   
        &BlinkyTaskHandle,   
        0  // Core 0  
    );  
    
    if(xReturned != pdPASS) {  
        printf("Failed to create Blinky task\n");  
        // Xử lý lỗi  
    }  
    
    xReturned = xTaskCreatePinnedToCore(  
        HelloWorld_Task,   
        "HelloWorld",   
        TASK_STACK_SIZE,   
        NULL,   
        TASK_PRIORITY,   
        &HelloWorldTaskHandle,   
        1  // Core 1  
    );  
    
    if(xReturned != pdPASS) {  
        printf("Failed to create HelloWorld task\n");  
        // Xử lý lỗi  
    }  
}  