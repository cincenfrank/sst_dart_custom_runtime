int calculate() {
  int counter = 0;
  for (var i = 0; i < 1000000; i++) {
    counter = counter + 1;
  }
  return counter;
}
