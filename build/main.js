var LCD_I2C_ADDR = 0x27;
var lcd;
var SENSOR_GPIO = 13; // sensor
var count = 0; // visitor count
var detected = false; // detected
var LED_GPIO = 23; // LED
var str = 'Welcome PLASK!! ';

function init() {
  Raspi.init();
  var i2c = new RaspiI2C(RaspiI2C.BSC1);
  lcd = new LCD_I2C(LCD_I2C_ADDR, i2c);
  lcd.init();
}

function mainloop() {
  while (true) {
    if (Raspi.gpioRead(SENSOR_GPIO)) {
      if (!detected) { // 検知した
        count++;
        Raspi.gpioWrite(LED_GPIO,1);
      }
      detected = true;
    } else { // 検知してない
      Raspi.gpioRead(LED_GPIO,0);
      detected = false;
    }
    display(count);
    Time.delay(700);
  }
}

function display(num) {
  lcd.setCursor(0, 0); // 0行0列
  lcd.printStr(str);
  str = str_scroll(str);

  lcd.setCursor(0, 1); // 1行0列
  lcd.printStr('Visitor: '+ num);
}

function str_scroll(st) {
  var tmp = st.charAt(0);
  st = st.slice(1,16);
  st = st + tmp;
  return st;
}

function main() {
  init();
  while (true) {
    mainloop();
  }
}

main();
