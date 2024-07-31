// I2C device class (I2Cdev) demonstration Processing sketch for MPU6050 DMP output
// 6/20/2012 by Jeff Rowberg <jeff@rowberg.net>
// Updates should (hopefully) always be available at https://github.com/jrowberg/i2cdevlib
//
// Changelog:
//     2012-06-20 - initial release
//     2016-10-28 - Changed to bi-plane 3d model based on tutorial at  
//                  https://forum.processing.org/two/discussion/24350/display-obj-file-in-3d
//                  https://opengameart.org/content/low-poly-biplane

/* ============================================
I2Cdev device library code is placed under the MIT license
Copyright (c) 2012 Jeff Rowberg

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
===============================================
*/

import processing.serial.*;
//import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;

// NOTE: requires ToxicLibs to be installed in order to run properly.
// 1. Download from https://github.com/postspectacular/toxiclibs/releases
// 2. Extract into [userdir]/Processing/libraries
//    (location may be different on Mac/Linux)
// 3. Run and bask in awesomeness

ToxiclibsSupport gfx;

Serial port;                         // The serial port
char[] teapotPacket = new char[14];  // InvenSense Teapot packet
int serialCount = 0;                 // current packet byte position
int synced = 0;
int interval = 0;

float[] q = new float[4];
Quaternion quat = new Quaternion(1, 0, 0, 0);

float[] gravity = new float[3];
float[] euler = new float[3];
float[] ypr = new float[3];


PShape plane; // 3d model

void setup() {
    // 640x480 px square viewport 
    size(640, 480, P3D);
    gfx = new ToxiclibsSupport(this);

    // setup lights and antialiasing
    lights();
    smooth();
  
    // display serial port list for debugging/clarity
    println(Serial.list());

    // get a specific serial port
    String portName = "COM19";
    
    // open the serial port
    port = new Serial(this, portName, 115200);
    
    // send single character to trigger DMP init/start
    // (expected by MPU6050_DMP6 example Arduino sketch)
    port.write('r');
        
    // The file must be in the \data folder
    // of the current sketch to load successfully
    plane = loadShape("micro_mo.obj"); 
 
 
    // apply its texture and set orientation 
    //PImage img1=loadImage("diffuse_512.png");
    //plane.setTexture(img1);
    plane.scale(7000);
    plane.rotateX(PI-HALF_PI);
    plane.rotateY(2*PI);

      
}

void draw() {
    if (millis() - interval > 1000) {
        // resend single character to trigger DMP init/start
        // in case the MPU is halted/reset while applet is running
        port.write('r');
        interval = millis();
    }

    // black background
    background(0);
   
      
    // translate everything to the middle of the viewport
    pushMatrix();
    translate(width / 2, height / 2);

    float[] axis = quat.toAxisAngle();
    rotate(axis[0], -axis[1], axis[3], axis[2]);

    // draw plane
    shape(plane, 0, 0);    
    
    popMatrix();
}


boolean isCalibrated = false;   // Flag to check if calibration is complete
float yawBaseline = 0;          // Stores the baseline yaw
int yawCalibrationCount = 0;    // Counts the calibration iterations
float yawCalibrationSum = 0;    // Sum of yaw values for calibration

void serialEvent(Serial port) {
    interval = millis();
    while (port.available() > 0) {
        int ch = port.read();

        if (synced == 0 && ch != '$') return;   // initial synchronization - also used to resync/realign if needed
        synced = 1;
        print ((char)ch);

        if ((serialCount == 1 && ch != 2)
            || (serialCount == 12 && ch != '\r')
            || (serialCount == 13 && ch != '\n'))  {
            serialCount = 0;
            synced = 0;
            return;
        }

        if (serialCount > 0 || ch == '$') {
            teapotPacket[serialCount++] = (char)ch;
            if (serialCount == 14) {
                serialCount = 0; // restart packet byte position

                // get quaternion from data packet
                q[0] = ((teapotPacket[2] << 8) | teapotPacket[3]) / 16384.0f;
                q[1] = ((teapotPacket[4] << 8) | teapotPacket[5]) / 16384.0f;
                q[2] = ((teapotPacket[6] << 8) | teapotPacket[7]) / 16384.0f;
                q[3] = ((teapotPacket[8] << 8) | teapotPacket[9]) / 16384.0f;
                for (int i = 0; i < 4; i++) if (q[i] >= 2) q[i] = -4 + q[i];

                // set our toxilibs quaternion to new data
                quat.set(q[0], q[1], q[2], q[3]);

                // calculate yaw
                float currentYaw = q[3];

                // Calibration process
                if (!isCalibrated) {
                    if (yawCalibrationCount < 20) {
                        yawCalibrationSum += currentYaw;
                        yawCalibrationCount++;
                    } else {
                        yawBaseline = yawCalibrationSum / 20;
                        isCalibrated = true;
                    }
                } else {
                    // Adjust the yaw using the baseline
                    ypr[0] = currentYaw - yawBaseline;
                }

                // Output various components for debugging
                if (isCalibrated) {
                    println("Calibrated Yaw: " + ypr[0]);
                }
            }
        }
    }
}
