
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "led_strip.h"
#include "sdkconfig.h"

#include "freeRTOS\freeRTOS.h"
#include "freeRTOS\task.h"
#define LED CONFIG_BLINK_GPIO

void app_main(void)
{
gpio_set_direction (LED, GPIO_MODE_DEF_OUTPUT);
while(1)
{
gpio_set_level (LED, 1);
vTaskDelay(100);
gpio_set_level (LED, 0);
vTaskDelay(100);
}
}