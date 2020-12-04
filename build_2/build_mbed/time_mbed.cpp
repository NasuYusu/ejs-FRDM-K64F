#include <stdio.h>
#include "mbed.h"
#include "time_mbed.h"

Timer t;

void start_time() {
  t.reset();
  t.start();
}

void end_time() {
  t.stop();
  printf("run time (us) : %d\n\r", t.read_us());
  //printf("run time(hrus) : %lld\n\r", t.read_high_resolution_us()); /* 64bit Integer */
}