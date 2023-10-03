;Includes
;-----------------------------------------------{
    include "CMC32A128.asm"
    include "macros.asm"
    defc BASE = ROM_BANK1
    defc BASE_PAGE = 0x11
    include "vector.asm"
    include "drivers/serial.asm"
    include "drivers/romfs.asm"
    include "drivers/fat.asm"
    include "drivers/stdio.asm"
    include "drivers/math.asm"
;-----------------------------------------------}
;Variables
;-----------------------------------------------{
    dsect
DataStack:
        dc 256
DataStackEnd:
Stack:
        dc 256
StackEnd:
    dend
;-----------------------------------------------}
;Functions
;-----------------------------------------------{

;Main function
Main:
        ;switch high bank to bank 2 for 32k flat rom space
        ld a, 0x21
        out (ROM_BA), a
        ld sp, StackEnd
        ld ix, DataStackEnd
        DSPushN BAUD115200
        call Serial1.init
        DSRestore 1

        DSPushNN Serial1.putc
        DSPushNN Serial1.getc
        call stdio.init
        DSRestore 4

        DSPushNN .message
        call Serial1.puts
        DSRestore 2

        DSPushNN .message2
        call Serial1.puts
        DSRestore 2

        DSPushNN (-420)
        call stdio.puts16d
        DSRestore 2

        DSPushN '\n'
        call Serial1.putc
        DSRestore 1

        DSPushNN ROMFsRead
        DSPushNN 0x0000
        call FAT.init
        DSRestore 4
        
    .loop:
        jr .loop

    .message:
        string "Hello World!\n"
    .message2:
        string "Test number output: "


;-----------------------------------------------}
;Post program include
;Needs to be at the end
    include "defaultDefines.asm"