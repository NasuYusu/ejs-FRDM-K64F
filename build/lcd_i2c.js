// commands
LCD_CLEARDISPLAY = 0x01;
LCD_RETURNHOME = 0x02;
LCD_ENTRYMODESET = 0x04;
LCD_DISPLAYCONTROL = 0x08;
LCD_CURSORORDISPLAYSHIFT = 0x10;
LCD_FUNCTIONSET = 0x20;
LCD_SETCGRAMADDR = 0x40;
LCD_SETDDRAMADDR = 0x80;

// flags for back light
LCD_BACKLIGHT = 0x08;
LCD_NOBACKLIGHT = 0x00;

// flags for display control
LCD_DISPLAYCONTROL_DISPLAY_ON  = 0x04;
LCD_DISPLAYCONTROL_CURSOR_ON   = 0x02;
LCD_DISPLAYCONTROL_BLINK_ON    = 0x01;

// flags for entry mode set
LCD_ENTRYMODESET_INCDEC_RIGHT = 0x02; // cursor/blink moves to right and DDRAM addrress is increased by 1.
LCD_ENTRYMODESET_INCDEC_LEFT  = 0x00; // cursor/blink moves to left and DDRAM addrress is increased by 1.
LCD_ENTRYMODESET_SH_ON        = 0x01; // shifting entire of display is performed according to INCDEC value. (I/D=high, left shift. I/D=low, right shift)
LCD_ENTRYMODESET_SH_OFF       = 0x00; // shifting entire of display is not performed.

// flags for cursor or display shift
LCD_CURSORORDISPLAYSHIFT_RIGHT    = 0x04;
LCD_CURSORORDISPLAYSHIFT_LEFT     = 0x00;
LCD_CURSORORDISPLAYSHIFT_CURSOR   = 0x08;
LCD_CURSORORDISPLAYSHIFT_DISPLAY  = 0x00;

// flags for function set
LCD_FUNCTIONSET_8BITMODE = 0x10;
LCD_FUNCTIONSET_4BITMODE = 0x00;
LCD_FUNCTIONSET_2LINE    = 0x08;
LCD_FUNCTIONSET_1LINE    = 0x00;
LCD_FUNCTIONSET_5x11DOTS = 0x04;
LCD_FUNCTIONSET_5x8DOTS  = 0x00;



En = 0x04; // enable bit
Rw = 0x02; // read/write bit
Rs = 0x01; // register select bit


function LCD_I2C(_lcd_i2c_addr, _i2c) {

  var lcd_i2c_addr = _lcd_i2c_addr;
  var i2c = _i2c;

  var displaycontrol;
  var displayfunction;
  var backlightval = LCD_BACKLIGHT;

  var debugMode = false;

  /*
   * API
   */
  this.init = function() {
    debugPrint('initializing');
    delay(50);
    expanderWrite(backlightval);
    delay(1000);

    // put the LCD into 4 bit mode
    write4bits(0x03 << 4);
    udelay(4500); // wait min 4.1ms
    write4bits(0x03 << 4);
    udelay(4500); // wait min 4.1ms
    write4bits(0x03 << 4);
    udelay(150);
    write4bits(0x02 << 4);

    // function set
    //displayfunction = LCD_4BITMODE | LCD_2LINE | LCD_5x8DOTS;
    displayfunction = LCD_FUNCTIONSET_4BITMODE | LCD_FUNCTIONSET_2LINE | LCD_FUNCTIONSET_5x8DOTS;
    command(LCD_FUNCTIONSET | displayfunction);

    debugPrint('entered 4 bit mode');

    // display on/off
    displaycontrol = LCD_DISPLAYCONTROL_DISPLAY_ON;
    this.display();

    // clear it off
    this.clear();

    // set the entry mode
    var entrymode = LCD_ENTRYMODESET_INCDEC_RIGHT | LCD_ENTRYMODESET_SH_OFF
    this.entrymodeset(entrymode);

    // return home
    this.home();

  }
  this.noDisplay = function() {
    displaycontrol &= ~LCD_DISPLAYCONTROL_DISPLAY_ON;
    command(LCD_DISPLAYCONTROL | displaycontrol);
  }
  this.display = function() {
    displaycontrol |= LCD_DISPLAYCONTROL_DISPLAY_ON;
    command(LCD_DISPLAYCONTROL | displaycontrol);
  }
  this.shiftCursor = function(sh) {
    if (sh != LCD_CURSORORDISPLAYSHIFT_LEFT &&
        sh != LCD_CURSORORDISPLAYSHIFT_RIGHT)  {
      return undefined;
    }
    command(LCD_CURSORORDISPLAYSHIFT | LCD_CURSORORDISPLAYSHIFT_CURSOR | sh);
  }
  this.shiftDisplay = function(sh) {
    if (sh !== LCD_CURSORORDISPLAYSHIFT_LEFT &&
        sh !== LCD_CURSORORDISPLAYSHIFT_RIGHT)  {
      return undefined;
    }
    command(LCD_CURSORORDISPLAYSHIFT | LCD_CURSORORDISPLAYSHIFT_DISPLAY | sh);
  }
  this.clear = function() {
    command(LCD_CLEARDISPLAY);
    udelay(2000);
  }
  this.entrymodeset = function(entrymode) {
    command(LCD_ENTRYMODESET | entrymode);
    udelay(2000);
  }
  this.home = function() {
    command(LCD_RETURNHOME);
    udelay(2000);
  }
  this.setCursor = function(col, row) {
    var row_offsets = [ 0x00, 0x40, 0x14, 0x54 ];
    if (!command(LCD_SETDDRAMADDR | (col + row_offsets[row]))) return false;
    return true;
  }
  this.noBacklight = function() {
    backlightval = LCD_NOBACKLIGHT;
    expanderWrite(0);
  }
  this.backlight = function() {
    backlightval = LCD_BACKLIGHT;
    expanderWrite(0);
  }
  this.printStr = function(s) {
    for (var i = 0; i < s.length; i++) {
      if (!write(s.charCodeAt(i))) return false;
    }
    return true;
  }
  this.putChar = function(c) {
    write(c & 0xff);
  }
  this.setDebugMode = function(flg) {
    debugMode = flg;
  }


  var command = function(value) {
    debugPrint('command: '+value);
    if (!send(value, 0)) return false;
    return true;
  }
  var write = function(value) {
    debugPrint('write: '+value);
    if (!send(value, Rs)) return false;
    return true;
  }
  var send = function(value, mode) {
    var highnib = value & 0xf0;
    var lownib = (value<<4) & 0xf0;
    if (!write4bits((highnib)|mode)) return false;
    if (!write4bits((lownib)|mode)) return false;
    return true;
  }
  var write4bits = function(value) {
    if (!expanderWrite(value)) return false;
    if (!pulseEnable(value)) return false;
    return true;
  }
  var expanderWrite = function(data) {
    if (!(i2c.write(lcd_i2c_addr, data | backlightval))) {
      debugPrint('error: expanderWrite');
      return false;
    }
    return true;
  }
  var pulseEnable = function(data) {
    if (!expanderWrite(data | En)) return false;
    udelay(1);
    if (!expanderWrite(data & ~En)) return false;
    udelay(50);
    return true;
  }
  var delay = function(t) {
    Time.delay(t);
  }
  var udelay = function(t) {
    Time.udelay(t);
  }
  var debugPrint = function(s) {
    if (debugMode) print('LCD_I2C message: '+s);
  }

}
