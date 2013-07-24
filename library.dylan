module: dylan-user

define library robots
  use common-dylan;
  use io;
  use termbox;
end library;

define module robots
  use common-dylan, exclude: { format-to-string };
  use format-out;
  use simple-random;
  use termbox;
end module;
