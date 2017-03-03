asm86 queue.asm m1 ep db
asm86 motor.asm m1 ep db
asm86 parser.asm m1 ep db
asm86 serial.asm m1 ep db
asm86 mainloopmotor.asm m1 ep db
asm86 timer0.asm m1 ep db
asm86 trigtbl.asm m1 ep db
asm86 init.asm m1 ep db
link86 mainloopmotor.obj, queue.obj, motor.obj, parser.obj, serial.obj, timer0.obj, trigtbl.obj, init.obj
LOC86 mainloopmotor.lnk TO mainloopmotor NOIC AD(SM(CODE(05000H),DATA(1000H), STACK(8000H)))
