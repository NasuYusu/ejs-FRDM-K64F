#include <stdio.h>
#include "mbed.h"
#include "time_mbed.h"

Timer t;
Timer gct;

void start_time() {
  t.reset();
  t.start();
}

int end_time() {
  t.stop();
  return t.read_us();
  //printf("run time(hrus) : %lld\n\r", t.read_high_resolution_us()); /* 64bit Integer */
}

void start_gctime() {
  //gct.reset();
  gct.start();
}

void end_gctime() {
  gct.stop();
  //return gct.read_us();
}

int get_gctime() {
  return gct.read_us();
}