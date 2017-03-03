asm86 converts.asm m1 ep db
asm86 display.asm m1 ep db
asm86 keypad.asm m1 ep db
asm86 serial.asm m1 ep db
asm86 mainloopkeypad.asm m1 ep db
asm86 queue.asm m1 ep db
asm86 timer2.asm m1 ep db
asm86 int2.asm m1 ep db
asm86 segtable.asm m1 ep db
asm86 init.asm m1 ep db
link86 mainloopkeypad.obj, converts.obj, timer2.obj, display.obj, keypad.obj, serial.obj, queue.obj, segtable.obj, init.obj
LOC86 mainloopkeypad.lnk TO mainloopkeypad NOIC AD(SM(CODE(04000H),DATA(0500H), STACK(7000H)))
