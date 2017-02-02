/*  
 *  ------ [DM_09] - set low power state in XBee module  -------- 
 *  
 *  Explanation: This program shows how to set the cyclic sleep mode
 *  in XBee-Digimesh modules. In order to coordinate a whole sleeping 
 *  network it is mandatory to switch on a network coordinator which
 *  SM must be set to '7' and its SO parameter must be set to '1' so 
 *  as to be a coordinator.     
 *
 *  Copyright (C) 2015 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 *  
 *  This program is free software: you can redistribute it and/or modify 
 *  it under the terms of the GNU General Public License as published by 
 *  the Free Software Foundation, either version 3 of the License, or 
 *  (at your option) any later version. 
 *  
 *  This program is distributed in the hope that it will be useful, 
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *  GNU General Public License for more details. 
 *  
 *  You should have received a copy of the GNU General Public License 
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
 *  
 *  Version:           0.2
 *  Design:            David Gascón 
 *  Implementation:    Yuri Carmona
 */

#include <WaspXBeeDM.h>
#include <WaspFrame.h>
#include <WaspSensorGas_Pro.h>


Gas SO2(SOCKET_1);
Gas CO(SOCKET_2);
Gas CH4(SOCKET_3);
//Gas O2(SOCKET_4);
//Gas NO(SOCKET_5);
Gas NO2(SOCKET_6);

float concentration;	// Stores the concentration level in ppm
float temperature; 
float humidity; 
float pressure;
float concSO2;
float concCO;
float concCH4;
//float concO2;
//float concNO;
float concNO2;

// SP parameter: Time to be asleep -> 5 seconds: 0x0001F4 (hex format, time in units of 10ms)
// Other possible values: 
//   0x0003E8 (10 seconds)
//   0x0000C8 (2 seconds)
//   0x0005DC (15 seconds)
//   0x001770 (60 seconds)
uint8_t asleep[3]={ 0x00,0x01,0xF4};

// ST parameter: Time to be awake -> 5 seconds: 0x001388 (hex format, time in units of 1ms)
// Other possible values: 
//   0x002710 (10 seconds)
//   0x0007D0 (2 seconds)
//   0x003A98 (15 seconds)
//   0x00EA60 (60 seconds)
uint8_t awake[3]={ 0x00,0x13,0x88};

// deifne variable to get running time
unsigned long startTime;

// PAN (Personal Area Network) Identifier
uint8_t  panID[2] = {0x7F,0xFF}; 

// Define Unicast
//////////////////////////////////////////
char RX_ADDRESS[] = "0013A20040794b68";

// Define the Waspmote ID
char WASPMOTE_ID[] = "SE-Node5";

// define variable
uint8_t error;

void setup()
{
  // Init USB port
  USB.ON();
  USB.println(F("Cyclic sleep example"));

  // init RTC 
  RTC.ON();

  //////////////////////////
  // 1. XBee setup
  //////////////////////////

  // 1.1. init XBee
  xbeeDM.ON();
  
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
//%%%%%%%%%%%%%%%%%%%%%%%%Slepp setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

  // 1.2. set time the module remains awake (ST parameter)
  xbeeDM.setAwakeTime(awake);
  
  // check AT command flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.println(F("ST parameter set ok"));
  }
  else 
  {
    USB.println(F("error setting ST parameter")); 
  }

  // 1.3. set Sleep period (SP parameter)
  xbeeDM.setSleepTime(asleep);
  
  // check AT command flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.println(F("SP parameter set ok"));
  }
  else 
  {
    USB.println(F("error setting SP parameter")); 
  }

  // 1.4. set sleep mode for cyclic sleep mode
  xbeeDM.setSleepMode(8);  
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End Sleep %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Setup Radio X900 %%%%%%%%%%%%%%%%%%%%%%%

// set Waspmote identifier
  frame.setID(WASPMOTE_ID);
xbeeDM.setNodeIdentifier(WASPMOTE_ID);

   /////////////////////////////////////
  // 2. set PANID
  /////////////////////////////////////
  xbeeDM.setPAN( panID );
  // check the AT commmand execution flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.print(F("2. PAN ID set OK to: 0x"));
    USB.printHex( xbeeDM.PAN_ID[0] ); 
    USB.printHex( xbeeDM.PAN_ID[1] ); 
    USB.println();
  }
  else 
  {
    USB.println(F("2. Error calling 'setPAN()'"));  
  }  
  
   // 1.5 Mesh Network Retries (4.7 manual digimesh)
  xbeeDM.setMeshNetworkRetries(0x03); 
    
  /////////////////////////////////////
  // 5. write values to XBee module memory
  /////////////////////////////////////
  xbeeDM.writeValues();

  // check the AT commmand execution flag
  if( xbeeDM.error_AT == 0 ) 
  {
    USB.println(F("5. Changes stored OK"));
  }
  else 
  {
    USB.println(F("5. Error calling 'writeValues()'"));   
  }

  USB.println(F("-------------------------------")); 
  
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
//%%%%%%%%%%%%%%%%%%%%%%%%End Radio Setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

}


void loop()
{  
  ///////////////////////////////////////////////
  // 2. Waspmote sleeps while XBee sleeps
  ///////////////////////////////////////////////

  // Waspmote enters to sleep until XBee module wakes it up
  // It is important not to switch off the XBee module when
  // entering sleep mode calling PWR.sleep function
  // It is necessary to enable the XBee interrupt

  // get starting time
  startTime = RTC.getEpochTime();

  USB.println(F("Enter deep sleep..."));
  
  // 2.1. enables XBEE Interrupt
  enableInterrupts(XBEE_INT);

  // 2.2. Waspmote enters sleep mode
  PWR.sleep( SENS_OFF );


  ///////////////////////////////////////////////
  // 3. Waspmote wakes up and check intFlag
  ///////////////////////////////////////////////

  USB.println(F("...wake up!"));

  // init RTC 
  RTC.ON();
  
  USB.print(F("Sleeping time (seconds):"));
  USB.println( RTC.getEpochTime() - startTime );
 
  
  // After waking up check the XBee interrupt
  if( intFlag & XBEE_INT )
  {
    // blink the red LED
    Utils.blinkRedLED();

    USB.println(F("--------------------"));
    USB.println(F("XBee interruption captured!!"));
    USB.println(F("--------------------"));
    
    intFlag &= ~(XBEE_INT); // Clear flag
  }

  /* Application transmissions should be done here when XBee
   module is awake for the defined awake time. All operations
   must be done during this period before teh XBee modules enters
   a sleep period again*/
   
   //Power on sensors
  SO2.ON();
  CO.ON();
  CH4.ON();
  //O2.ON();
  NO2.ON();
   
    // Sensors need time to warm up and get a response from gas
  // To reduce the battery consumption, use deepSleep instead delay
  // After 2 minutes, Waspmote wakes up thanks to the RTC Alarm  
  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  
  USB.println(F(" Turn on Sensors "));
  
  USB.println(F(" Read Sensors "));
   // Read the CO sensor and compensate with the temperature internally
   concentration = CO.getConc();
  // Read the CO2 sensor and compensate with the temperature internally
  concCO = SO2.getConc();
  // Read the CO sensor and compensate with the temperature internally
  concCO = CO.getConc();
  // Read the O3 sensor and compensate with the temperature internally
  concCH4 = CH4.getConc();
  // Read the O2 sensor and compensate with the temperature internally
 // concO2 = O2.getConc();
  // Read the NO sensor and compensate with the temperature internally
  //concNO = NO.getConc();
  // Read the NO2 sensor and compensate with the temperature internally
  concNO2 = NO2.getConc();
  
  // Read enviromental variables
  temperature = CO.getTemp();
  humidity = CO.getHumidity();
  pressure = CO.getPressure();
  
  
//Power off sensors
  SO2.OFF();
  CO.OFF();
  CH4.OFF();
  //O2.OFF();
  //NO.OFF();
  NO2.OFF();
USB.println(F("Sensor Board off"));
///////////////////////////////////////////
// 3. Create ASCII frame or Create Binnary frame
/////////////////////////////////////////// 


// Or %%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
 
///////////////////////////////////////////
// Create ASCII frame
/////////////////////////////////////////// 

// Create new frame
    USB.println(F("Create a new Frame:"));
    frame.createFrame(ASCII);  
    
    // Add temperature
  frame.addSensor(SENSOR_GP_TC, temperature);
  // Add humidity
  frame.addSensor(SENSOR_GP_HUM, humidity);
  // Add pressure value
  frame.addSensor(SENSOR_GP_PRES, pressure);
  // Add CO2 value
  frame.addSensor(SENSOR_GP_CO, concCO);
  // Add CO value
   frame.addSensor(SENSOR_GP_SO2, concSO2);
  // Add O3 value
  frame.addSensor(SENSOR_GP_CH4, concCH4);
  // Add O2 value
  //frame.addSensor(SENSOR_GP_O2, concO2);
  // Add NO value
  //frame.addSensor(SENSOR_GP_NO, concNO);
  // Add NO2 value
  frame.addSensor(SENSOR_GP_NO2, concNO2); 
  
// Create frame fields
    frame.addSensor(SENSOR_STR, "7C05");
    frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel()); 
  frame.showFrame();
///////////////////////////////////////////
// 4. Send packet
///////////////////////////////////////////  

// send XBee packet
    error = xbeeDM.send( RX_ADDRESS, frame.buffer, frame.length );   
  
// check TX flag
  if( error == 0 )
  {
    USB.println(F("send ok"));
    
// blink green LED
    Utils.blinkGreenLED();
    
  }
     else 
  {
     USB.println(F("send error"));
    
// blink red LED
     Utils.blinkRedLED();
}

  // do nothing while XBee module remains awake before 
  // return to sleep agains after 'awake' seconds
  delay(1000);
}


