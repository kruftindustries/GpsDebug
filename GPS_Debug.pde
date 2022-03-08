//** GPS Development/Debug utility, SirfStarV 5e.
//** Written as a utility for the KI-RTK imu/gps receiver
//** Source is on github, website is http://kruftindustries.com
//** If you find this software useful, consider donating
//** https://PayPal.Me/KRUFTINDUSTRIES/
/*
    Copyright (C) 2018 Kruft Industries LLC
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import processing.serial.*;


//Set to true to run/debug without serial port and uncomment/comment SV declaration below
static final private boolean DEBUG = true;

//Test Data (uncomment for test data without serial port)
int[][] SV = new int[][] {{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, {19, 58, 283, 24, 1, 0}, {30, 21, 171, 8, 0, 1}, {24, 15, 317, 34, 1, 1}, {28, 58, 91, 16, 0, 1}, {01, 22, 43, 18, 1, 1}, {11, 10, 49, 0, 1, 1}, {06, 88, 239, 41, 1, 1}, {22, 14, 64, 0, 0, 1}, {13, 5, 243, 0, 1, 1}, {78, 64, 319, 22, 1, 1}, {81, 24, 240, 23, 0, 1}};
//int[][] SV = new int[235][8];




Serial myPort;  // Create object from Serial class
int val, checksum;      // Data received from the serial port
String serialbuff = "", hexsum = "", tempsum = "", message = "", data = "", fixtype = "No Fix", time ="";
boolean messagePending, messagechecked = false;

int svtimeout = 2000; //Number of draw iterations before a satellite is removed from the constellation
float[] DOP = new float[3];





//Setup loop
void setup() {
  size(280, 400);
  background(255);   
    
if (DEBUG) {
  } else {
    String portName = Serial.list()[0];
    //Set your serial port here!!!   ^

    myPort = new Serial(this, portName, 115200);
    //Set your baudrate above
  }
}




//Main loop
void draw() {

  // Translate the origin point to the center of the screen
  translate(width/2, height/2-50);

  //Draw Chart
  draw_Chart();

  //Parse NMEA 
  read_NMEA();

  //Draw satellite constellation
  draw_SV(SV);

  //Draw signal strength
  draw_SNR(SV);
}




//Begin subroutine definitions



//Read and parse NMEA data
int[][] read_NMEA() {
  //Buffer for satellite data
  int[][] tempSV = new int[100][8];
  if (DEBUG) {
  } else { 
    if ( myPort.available() > 0) {  // If data is available,
      val = myPort.read();         // read it and store it in val
    }
  }


  if ( val == '$') {
    serialbuff = "";
    tempsum = "";
    messagePending = true;
    messagechecked = false;
  }

  if ( val == '*' & serialbuff != "") {
    // Compute the checksum by XORing all the character values in the string.
    checksum = 0;
    serialbuff = serialbuff.substring(1);
    for (int i = 0; i < serialbuff.length(); i++) {
      checksum = checksum ^ serialbuff.charAt(i);
    }
    // Convert it to hexadecimal.
    hexsum = hex(checksum, 2);
    messagechecked = true;
  }

  if ( messagechecked & val != '\r' & val != '*') {
    tempsum += char(val);
  }

  if ( messagePending & !messagechecked) {
    serialbuff += char(val);
  }

  if (tempsum != "" & hexsum.equals(tempsum) & messagechecked) {
    messagechecked = false;
    message = serialbuff.substring(0, 5);
    data = serialbuff.substring(5);
    //println("WOOOOO: " + message);

    if ("GPGGA".equals(message)) {
      println("GGA: " + data);
      String[] temp = split(data, ',');
      time = str(temp[1].charAt(0)) + str(temp[1].charAt(1)) + ":" + str(temp[1].charAt(2)) + str(temp[1].charAt(3)) + ":" + str(temp[1].charAt(4)) + str(temp[1].charAt(5)) + " UTC";
      message = "";
      data = "";
    }
    if ("GPZDA".equals(message)) {
      //hhmmss.ss,dd,mm,yyyy,xx,yy
      println("ZDA: " + data);
      //String[] temp = split(data,',');

      //time = "UTC:" + temp[0] + " Day:" + temp[1] + " Month:" + temp[2] + " Year:" + temp[3] + " Local:" + temp[4] + ":" + temp[5];

      message = "";
      data = "";
    } else if ("GNRMC".equals(message)) {
      //println("gnrmc: " + message);
      message = "";
      data = "";
    } else if ("GNGSA".equals(message)) {
      println("GNGSA: " + data);
      String[] temp = split(data, ',');

      if (temp[2].equals("")) fixtype = "No Fix";
      if (temp[2].equals("1")) fixtype = "No Fix";
      if (temp[2].equals("2")) fixtype = "2D Fix";
      if (temp[2].equals("3")) fixtype = "3D Fix";

      //temp = subset(temp, 2);
      //println(temp);
      updateGSA(temp);



      message = "";
      data = "";
    } else if ("GPGSA".equals(message)) {
      println("GPGSA: " + message);
      message = "";
      data = "";
    }
    //gps constellation
    else if ("GPGSV".equals(message)) {
      println("GPS: " + data);
      String[] temp = split(data, ',');
      for (int i = 0; i < temp.length; i++) {
        if (temp[i] == "") temp[i] = "0";
      }
      temp = subset(temp, 4);
      //println(temp);
      updateGSV(temp);

      //println("data[" + i + "]:" + int(temp[i]));

      temp = subset(temp, 2);

      message = "";
      data = "";
    }
    //galileo constellation
    else if ("GAGSV".equals(message)) {
      println("GALILEO: " + data);
      String[] temp = split(data, ',');
      for (int i = 0; i < temp.length; i++) {
        if (temp[i] == "") temp[i] = "0";
      }
      temp = subset(temp, 4);
      //println(temp);
      updateGSV(temp);

      //println("data[" + i + "]:" + int(temp[i]));

      temp = subset(temp, 2);

      message = "";
      data = "";
    }
    //beidou constellation
    else if ("BDGSV".equals(message)) {
      println("BEIDOU: " + data);
      String[] temp = split(data, ',');
      for (int i = 0; i < temp.length; i++) {
        if (temp[i] == "") temp[i] = "0";
      }
      temp = subset(temp, 4);
      //println(temp);
      updateGSV(temp);

      temp = subset(temp, 2);

      message = "";
      data = "";
    }
    //beidou constellation
    else if ("GNGSV".equals(message)) {
      println("Generic: " + data);
      String[] temp = split(data, ',');
      for (int i = 0; i < temp.length; i++) {
        if (temp[i] == "") temp[i] = "0";
      }
      temp = subset(temp, 4);
      //println(temp);
      updateGSV(temp);

      //println("data[" + i + "]:" + int(temp[i]));

      temp = subset(temp, 2);

      message = "";
      data = "";
    }
    //glonass constellation
    else if ("GLGSV".equals(message)) {
      println("GLONASS: " + data);
      String[] temp = split(data, ',');
      for (int i = 0; i < temp.length; i++) {
        if (temp[i] == "") temp[i] = "0";
      }
      temp = subset(temp, 4);
      //println(temp);
      updateGSV(temp);

      message = "";
      data = "";
    } else if ("GNGNS".equals(message)) {
      //println("WOOOOO: " + message);
      message = "";
      data = "";
    } else {
      //println("WOOOOO: " + message);
      message = "";
      data = "";
    }
  } 



  return tempSV;
}





void updateGSV(String[] temp) {
  //println(temp);
  SV[int(temp[0])][0] = int(temp[0]);
  SV[int(temp[0])][1] = int(temp[1]);
  SV[int(temp[0])][2] = int(temp[2]);
  SV[int(temp[0])][3] = int(temp[3]);
  SV[int(temp[0])][5] = 0;
  SV[int(temp[0])][7] = 0;
  if (temp.length > 4) {
    SV[int(temp[4])][0] = int(temp[4]);
    SV[int(temp[4])][1] = int(temp[5]);
    SV[int(temp[4])][2] = int(temp[6]);
    SV[int(temp[4])][3] = int(temp[7]);
    SV[int(temp[4])][5] = 0;
    SV[int(temp[4])][7] = 0;
  }
  if (temp.length > 8) {
    SV[int(temp[8])][0] = int(temp[8]);
    SV[int(temp[8])][1] = int(temp[9]);
    SV[int(temp[8])][2] = int(temp[10]);
    SV[int(temp[8])][3] = int(temp[11]);
    SV[int(temp[8])][5] = 0;
    SV[int(temp[8])][7] = 0;
  }
  if (temp.length > 12) {
    SV[int(temp[12])][0] = int(temp[12]);
    SV[int(temp[12])][1] = int(temp[13]);
    SV[int(temp[12])][2] = int(temp[14]);
    SV[int(temp[12])][3] = int(temp[15]);
    SV[int(temp[12])][5] = 0;
    SV[int(temp[12])][7] = 0;
  }
}





void updateGSA(String[] temp) {
  if (temp.length-3 > 0) {
    SV[int(temp[3])][4] = 1;
  }
  if (temp.length-3 > 1) {
    SV[int(temp[4])][4] = 1;
  }
  if (temp.length-3 > 2) {
    SV[int(temp[5])][4] = 1;
  }
  if (temp.length-3 > 3) {
    SV[int(temp[6])][4] = 1;
  }
  if (temp.length-3 > 4) {
    SV[int(temp[7])][4] = 1;
  }
  if (temp.length-3 > 5) {
    SV[int(temp[8])][4] = 1;
  }
  if (temp.length-3 > 6) {
    SV[int(temp[9])][4] = 1;
  }
  if (temp.length-3 > 7) {
    SV[int(temp[10])][4] = 1;
  }
  if (temp.length-3 > 8) {
    SV[int(temp[11])][4] = 1;
  }
  if (temp.length-3 > 9) {
    SV[int(temp[12])][4] = 1;
  }
  if (temp.length-3 > 10) {
    SV[int(temp[13])][4] = 1;
  }
  if (temp.length-3 > 11) {
    SV[int(temp[14])][4] = 1;
  }
  DOP[0] = float(temp[15]);
  DOP[1] = float(temp[16]);
  DOP[2] = float(temp[17]);
}





//Draw SV Constellation
void draw_SV(int[][] tempSV) {
  float x, y;
  int r=45;
  textSize(5);
  for (int i = 1; i < tempSV.length; i++) {
    //elevation/azimuth to x,y
    x = r * cos(radians(tempSV[i][1])) * cos(radians(tempSV[i][2]-90));
    y = r * cos(radians(tempSV[i][1])) * sin(radians(tempSV[i][2]-90));
    if (tempSV[i][0] != 0 && tempSV[i][3] != 0) {
      if (tempSV[i][4] == 2)
      { 
        fill(0, 255, 0);
      }

      if (tempSV[i][4] == 1)
      { 
        fill(0, 0, 255);
      }

      if (tempSV[i][4] == 0)
      { 
        fill(255);
      }

      if (tempSV[i][5] == 2)
      { 
        triangle(x-5, y+4, x+3/2, y-7, x+5, y+4);
      }

      if (tempSV[i][5] == 1)
      { 
        rect(x-4, y-4, 8, 8);
      }

      if (tempSV[i][5] == 0)
      { 
        ellipse(x, y, 10, 10);
      }

      //ellipse(x, y, 10, 10);
      fill(0);
      text(tempSV[i][0], x, y-1);
    }
  }
}





//Draw SNR bars and info
void draw_SNR(int[][] tempSV) {
  int id1 = 0, id2 = 0, k = 0;
  float snr;
  textSize(6);
  for (int i = 1; i < tempSV.length; i++) {
    if (DEBUG) {
    } else { 
      tempSV[i][7] = tempSV[i][7]+1;
    }
 


    if (tempSV[i][3] != 0) k++;
    if (i < 33) SV[i][5] = 0; // GPS satellites
    if (i > 32 && i < 55) SV[i][5] = 2; // SBAS satellites(EGNOS, WAAS, SDCM, GAGAN, MSAS)
    if (i > 64 && i < 89) SV[i][5] = 1; // Glonass satellites
    if (tempSV[i][0] != 0 && tempSV[i][3] != 0) {
      fill(0);


      //Split satellite ID into two digits to save space
      if (tempSV[i][0] > 9)
      { 
        id1 = tempSV[i][0] / 10;
        id2 = tempSV[i][0] % 10;
      } 
      if (tempSV[i][0] < 9)
      { 
        id1 = 0;
        id2 = tempSV[i][0] % 10;
      }

      //Display satellite ID
      text(id1, -69+(k*6), 70);
      text(id2, -69+(k*6), 75);

      //Solid SNR Bar if satellite is used for position solution
      if (tempSV[i][4] == 0)
      { 
        fill(255);
      }
      if (tempSV[i][4] == 1)
      { 
        fill(0);
      }

      //Convert snr range to 0-20 and draw signal bar

      snr = map(tempSV[i][3], 0, 50, 0, 20);

      rect(-70+(k*6), 95+(20-snr), 4, snr);
    }
    if (DEBUG) {
    } else { 
      if  (tempSV[i][7] > svtimeout) {
        SV[i][3] = 0; 
        SV[i][4] = 0;
      }
    }
    fill(0);
    text(fixtype, -60, -65);
    text("PDOP " + DOP[0], -55, -60);
    text("HDOP " + DOP[1], -55, -55);
    text("VDOP " + DOP[2], -55, -50);
    text(time, -45, 120);
  }

}



  //Draw Constellation Chart
  void draw_Chart() {
    clear();
    background(255);
    // Prepare our constellation map
    ellipseMode(CENTER);
    scale(2);
    fill(255);
    //Draw chart circles
    ellipse(0, 0, 90, 90);
    ellipse(0, 0, 60, 60);
    ellipse(0, 0, 30, 30);
    line(0, -45, 0, 45);
    line(-45, 0, 45, 0);
    fill(0);
    textAlign(CENTER, CENTER);
    scale(1);
    textSize(14);
    //Draw headings
    text("N", -1, -58);
    text("W", -55, -1.6);
    text("E", 55, -1.6);
    text("S", -1, 52);
  }
