module: robots
synopsis: robots game
author: Francesco Ceccon
copyright: See LICENSE file in this distribution.

define class <player> (<object>)
  slot player-position :: <pair>,
    init-keyword: position:;
end class;

define class <board> (<object>)
  slot board-width :: <integer>,
    init-keyword: width:;
  slot board-height :: <integer>,
    init-keyword: height:;
  slot board-enemies :: <sequence>,
    init-keyword: enemies:;
  slot board-player :: <player>,
    init-keyword: player:;
end class;

define method board-origin (board :: <board>) => (origin :: <pair>)
  let term-width = tb-width();
  let term-height = tb-height();
  let origin = pair(round((term-width - board.board-width) / 2.0),
                    round((term-height - board.board-height) / 2.0));
  origin
end method;

define method draw-box (board :: <board>)
  let origin = board-origin(board);
  head(origin) := head(origin) - 1;
  tail(origin) := tail(origin) - 1;
  let hl = make(<string>, size: (board.board-width + 2), fill: '-');
  tb-print(head(origin), tail(origin), hl);
  tb-print(head(origin), tail(origin) + board.board-height + 2, hl);
  for (i from 0 below (board.board-height + 2))
    tb-print(head(origin), tail(origin) + i, '|');
    tb-print(head(origin) + board.board-width + 2, tail(origin) + i, '|');
  end for;
  tb-print(head(origin), tail(origin), '+');
  tb-print(head(origin) + board.board-width + 2, tail(origin), '+');
  tb-print(head(origin) + board.board-width + 2, tail(origin) + board.board-height + 2, '+');
  tb-print(head(origin), tail(origin) + board.board-height + 2, '+');
end method;

define method draw-player (board :: <board>)
  let origin = board-origin(board);
  let player = board.board-player;
  let p = player.player-position;
  tb-print(head(origin) + head(p), tail(origin) + tail(p), '@', fg: $TB-GREEN);
end method;

define method draw-enemies (board :: <board>)
  let origin = board-origin(board);
  for (enemy in board.board-enemies)
    tb-print(head(origin) + head(enemy), tail(origin) + tail(enemy), '#', fg: $TB-RED);
  end for;
end method;

define method draw (board :: <board>)
  draw-box(board);
  draw-player(board);
  draw-enemies(board);
end method;

define function move (player :: <player>, direction) => (moved? :: <boolean>)
  let x = head(player.player-position);
  let y = tail(player.player-position);
  select (direction)
    #"up" => y := y - 1;
    #"down" => y := y + 1;
    #"left" => x := x - 1;
    #"right" => x := x + 1;
  end;
  player.player-position := pair(x, y);
  #t
end;

define function teleport (board :: <board>)
  let x = random(board.board-width);
  let y = random(board.board-height);
  player-position(board.board-player) := pair(x, y);
end;

define function move-player(ev, board)
  let pos = player-position(board.board-player);
  let x = head(pos);
  let y = tail(pos);
  select (ev.event-ch)
    as(<integer>, 'k') => if (y > 0) move(board.board-player, #"up") end;
    as(<integer>, 'j') => if (y < board.board-height) move(board.board-player, #"down") end;
    as(<integer>, 'h') => if (x > 0) move(board.board-player, #"left") end;
    as(<integer>, 'l') => if (x < board.board-width) move(board.board-player, #"right") end;
    as(<integer>, '3') => teleport(board);
    otherwise => ;
  end
end function;

define function move-enemies (board :: <board>)
  let pos = player-position(board.board-player);
  for (enemy in board.board-enemies,
       i from 0)
    let dx = head(enemy) - head(pos);
    let dy = tail(enemy) - tail(pos);
    let mx = head(enemy) + if (dx < 0) 1 elseif (dx = 0) 0 else -1 end if;
    let my = tail(enemy) + if (dy < 0) 1 elseif (dy = 0) 0 else -1 end if;
    board.board-enemies[i] := pair(mx, my);
  end for;
end function;

define function collide! (board :: <board>)
  let enemies = board.board-enemies;
  let new-enemies = #[];
  // FIXME: Crappy algo
  for (i from 0 below size(enemies))
    let is-colliding? = #f;
    for (j from 0 below size(enemies))
      if (enemies[i] = enemies[j] & i ~= j)
        is-colliding? := #t;
      end;
    end for;
    if (~is-colliding?)
      new-enemies := add!(new-enemies, enemies[i]);
    end if;
  end for;
  board.board-enemies := new-enemies;
end;

define function player-lost? (board :: <board>) => (lost? :: <boolean>)
  let pos = player-position(board.board-player);
  let lost? = #f;
  for (enemy in board.board-enemies)
    if (pos = enemy)
      lost? := #t;
    end;
  end for;
  lost?
end function;

define function player-won? (board :: <board>) => (won? :: <boolean>)
  size(board.board-enemies) = 0
end function;

define function final-screen (text)
  tb-clear();
  block (exit)
    while (#t)
      let x = random(tb-width());
      let y = random(tb-height());
      tb-print(x, y, text, fg: $TB-RED);
      tb-present();

      let (t, ev) = tb-poll-event();
      select (ev.event-type)
        $TB-EVENT-KEY
          => exit();
        $TB-EVENT-RESIZE
          => /* Resize board */;
      end select;
    end while;
  end block;
end function;

define function victory-screen ()
  final-screen("YOU WON!!!");
end function;

define function defeat-screen ()
  final-screen("YOU LOST!!!");
end function;

define function main (name :: <string>, arguments :: <vector>)
  let player = make(<player>, position: pair(5, 5));
  let enemies = #[];
  for (i from 0 below 4)
    enemies := add!(enemies, pair(random(40), random(20)));
  end for;
  let board = make(<board>,
                   width: 40,
                   height: 20,
                   enemies: enemies,
                   player: player);
  tb-init();
  let won? = block (exit)
    while (#t)
      tb-clear();
      draw(board);
      tb-present();

      let (t, ev) = tb-poll-event();
      select (ev.event-type)
        $TB-EVENT-KEY
          => if (ev.event-key = $TB-KEY-ESC)
               exit();
             else
               case (player-won?(board))
                      => exit(#t);
                    (player-lost?(board))
                      => exit(#f);
                    otherwise
                      => move-enemies(board);
                         move-player(ev, board);
                         collide!(board);
               end case;
             end if;
        $TB-EVENT-RESIZE
          => /* Resize board */;
      end select;
    end;
  end block;

  if (won?)
    victory-screen();
  else
    defeat-screen();
  end;

  tb-shutdown();
  exit-application(0);
end function main;

main(application-name(), application-arguments());
