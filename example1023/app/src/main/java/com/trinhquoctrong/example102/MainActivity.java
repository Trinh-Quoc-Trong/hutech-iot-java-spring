package com.trinhquoctrong.example102;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallbackExtended;
import org.eclipse.paho.client.mqttv3.MqttMessage;

public class MainActivity extends AppCompatActivity {
    MqttHelper mqttHelper;
    TextView dataReceived;
    ImageView bulbImage;
    boolean isBulbOn = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        dataReceived = findViewById(R.id.dataReceived);
        bulbImage = findViewById(R.id.bulbImage);

        bulbImage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                isBulbOn = !isBulbOn;
                if (isBulbOn) {
                    bulbImage.setImageResource(R.drawable.bulb_on);
                    mqttHelper.publishMessage("/test/topic1", "1");
                } else {
                    bulbImage.setImageResource(R.drawable.bulb_off);
                    mqttHelper.publishMessage("/test/topic1", "0");
                }
            }
        });

        startMqtt();
    }

    private void startMqtt() {
        mqttHelper = new MqttHelper(getApplicationContext());
        mqttHelper.setCallback(new MqttCallbackExtended() {
            @Override
            public void connectComplete(boolean b, String s) {
            }

            @Override
            public void connectionLost(Throwable throwable) {
            }

            @Override
            public void messageArrived(String topic, MqttMessage mqttMessage) throws Exception {
                Log.w("Debug", mqttMessage.toString());
                runOnUiThread(() -> dataReceived.setText(mqttMessage.toString()));
            }

            @Override
            public void deliveryComplete(IMqttDeliveryToken iMqttDeliveryToken) {
            }
        });
    }
}