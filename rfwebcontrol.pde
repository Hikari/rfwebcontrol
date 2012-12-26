#include <SPI.h>
#include <Ethernet.h>
#include <RemoteSwitch.h>
#include <string.h>
#include <WebServer.h>
#include "avr/pgmspace.h" // new include

#define RF_PIN 11
#define VERSION_STRING "1.0"

//the Intertechno(klikaanklikuit) simulator
KaKuSwitch kaKuSwitch(5);


// no-cost stream operator as described at 
// http://sundial.org/arduino/?page_id=119
template<class T>
inline Print &operator <<(Print &obj, T arg)
{ obj.print(arg); return obj; }

//states of the switches
boolean s1, s2, s3 = 0;

/* CHANGE THIS TO YOUR OWN UNIQUE VALUE. The MAC number should be
* different from any other devices on your network or you'll have
* problems receiving packets. */
static uint8_t mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

static uint8_t ip[] = { 192, 168, 0, 177 };

P(Page_start) = "<html><head><meta name=\"viewport\" content=\"user-scalable=no, width=device-width, initial-scale=3.0\"/><meta name=\"apple-mobile-web-app-capable\" content=\"yes\" /><meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black\" /><title>RemLights Version " VERSION_STRING "</title><style>body{font-family: Helvetica}</style></head><body>\n";
P(Page_end) = "</body></html>";
P(Line_break) = "<br>\n";
P(Control) = "<li><a href=\"action?s1=1\">Switch 1</a></li><li><a href=\"action?s2=1\">Switch 2</a></li><li><a href=\"action?s3=1\">Switch 3</a></li>";

/* This creates an instance of the webserver.  By specifying a prefix
 * of "/", all pages will be at the root of the server. */
#define PREFIX ""
WebServer webserver(PREFIX, 80);


#define NAMELEN 32
#define VALUELEN 32

void parsedCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
  URLPARAM_RESULT rc;
  char name[NAMELEN];
  int  name_len;
  char value[VALUELEN];
  int value_len;
  
  server.httpSuccess();
  if (type == WebServer::HEAD)
    return;


  server.printP(Page_start);
  
  
  //parse the params
  if (strlen(url_tail))
  {
    while (strlen(url_tail))
    {
      rc = server.nextURLparam(&url_tail, name, NAMELEN, value, VALUELEN);
      if (rc != URLPARAM_EOS){
        //fetch tha params
        if (strncmp(name, "s1", 2) == 0){
          s1 = !s1;
          triggerRfSwitch(1, s1);
        }
        if (strncmp(name, "s2", 2) == 0){
          s2 = !s2;
          triggerRfSwitch(2, s2);
        }
        if (strncmp(name, "s3", 2) == 0){
          s3 = !s3;
          triggerRfSwitch(3, s3);
        }
        if (strncmp(name, "a", 1) == 0){
          s1 = s2 = s3 = (char)atoi(value);
          while(true){
            triggerRfSwitch(1, (char)atoi(value));
            triggerRfSwitch(2, (char)atoi(value));
            triggerRfSwitch(3, (char)atoi(value));
          }
        }
      }
    }
  }
  
  server << "<button onClick=\"javascript:parent.location='action?s1=1'\">Switch 1: " << (int)s1 << "</button><br/>";
  server << "<button onClick=\"javascript:parent.location='action?s2=1'\">Switch 2: " << (int)s2 << "</button><br/>";
  server << "<button onClick=\"javascript:parent.location='action?s3=1'\">Switch 3: " << (int)s3 << "</button><br/>";
  server << "<button onClick=\"javascript:parent.location='action?a=1'\">All ON</button><br/>";
  server << "<button onClick=\"javascript:parent.location='action?a=0'\">All OFF</button><br/>";
  

  server.printP(Page_end);
}

void triggerRfSwitch(int s, boolean state){
  Serial.print("Triggering switch: ");
  Serial.println(s);
  switch(s){
    case 1:
      digitalWrite(13, HIGH); 
      kaKuSwitch.sendSignal('B',1,s1);
      break;
    case 2:
      digitalWrite(13, HIGH); 
      kaKuSwitch.sendSignal('B',2,s2);
      break;
    case 3:
      digitalWrite(13, HIGH); 
      kaKuSwitch.sendSignal('B',3,s3);
      break;
  }
  delay(200);              // wait a little bit...  
  digitalWrite(13, LOW);
}

void setup()
{
  /* initialize the Ethernet adapter */
  Ethernet.begin(mac, ip);
  pinMode(13, OUTPUT);
  Serial.begin(9600);
  /* setup our default command that will be run when the user accesses
   * the root page on the server */
  webserver.setDefaultCommand(&parsedCmd);
  webserver.addCommand("action", &parsedCmd);
  /* start the webserver */
  webserver.begin();
}

void loop()
{
  char buff[64];
  int len = 64;

  /* process incoming connections one at a time forever */
  webserver.processConnection(buff, &len);
}

