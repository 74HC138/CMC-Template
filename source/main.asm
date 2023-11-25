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
FileEntryBuffer:
        dc 32
File1:
        dc FILE
FileBuffer:
        dc 101
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

        print .message3
        ld hl, (FAT.iRoot)
        DSPushHL
        call stdio.putu16h
        DSRestore 2
        printNL

        print .message4
        ld a, (FAT.RootCnt)
        DSPush a
        call stdio.putu8h
        DSRestore 1
        printNL

        print .message5
        call FAT.getRootFileCount
        ld c, a
        DSPush a
        call stdio.putu8h
        DSRestore 1
        printNL

        ld d, 0
    .listLoop:
            ld a, d
            cp c
            jp nc, .listExit
            DSPush d
            DSPushNN FileEntryBuffer
            call FAT.getRootFile
            DSRestore 3
            ld hl, .message6
            ld a, (FileEntryBuffer + 11)
            bit 4, a
            jr z, .listNoFolder
            ld hl, .message7
    .listNoFolder:
            DSPushHL
            call stdio.puts
            DSRestore 2
            ld a, 0
            ld (FileEntryBuffer + 11), a
            print FileEntryBuffer
            print .message8
            ld hl, (FileEntryBuffer + 28)
            DSPushHL
            call stdio.putu16h
            DSRestore 2
            printNL
            inc d
            jp .listLoop
    .listExit:

        DSPushN 0
        DSPushNN FileEntryBuffer
        call FAT.getRootFile
        DSRestore 3

        print .message9
        ld iy, FileEntryBuffer
        ld l, (iy + 26)
        ld h, (iy + 27)
        DSPushHL
        call stdio.putu16h
        DSRestore 2
        printNL

        print .message10
        DSPushHL
        call FAT.getNext
        DSRestore 2
        DSPushBC
        call stdio.putu16h
        DSRestore 2
        printNL

        print .message11
        ld iy, FileEntryBuffer
        ld a, 0
        ld (iy + 11), a
        print FileEntryBuffer
        printNL
        DSPushNN File1
        DSPushNN FileEntryBuffer
        call FAT.open
        DSRestore 4
        cp 0
        jr z, .openSucces
        ;fail
        print .message13
        jp .openExit
    .openSucces:
        print .message12
        print .message14
        DSPushNNin (File1 + FILE.Size + 2)
        DSPushNNin (File1 + FILE.Size)
        call stdio.putu32h
        DSRestore 4
        printNL
        print .message15
        DSPushNN File1
        DSPushNN FileBuffer
        DSPushNN 100
        call FAT.read
        DSRestore 6
        ld hl, (FileBuffer + 100)
        ld (hl), 0
        cp 0
        jr z, .dump:
        print .message16
        jr .openExit
    .dump:
        print FileBuffer
        printNL
    .openExit:


    .loop:
        jr .loop

    .message:
        string "Hello World!\n"
    .message2:
        string "Test number output: "
    .message3:
        string "Root entry index: "
    .message4:
        string "Root entry count: "
    .message5:
        string "Number of files in root: "
    .message6:
        string "File: "
    .message7:
        string "Folder: "
    .message8:
        string "  Size [bytes]: "
    .message9:
        string "First cluster of file #1: "
    .message10:
        string "Next cluster of file #1: "
    .message11:
        string "Opening file "
    .message12:
        string "Succes\n"
    .message13:
        string "Failure\n"
    .message14:
        string "File Size: "
    .message15:
        string "Dump of file:\n"
    .message16:
        string "Error reading file!\n"

;-----------------------------------------------}
;Post program include
;Needs to be at the end
    include "defaultDefines.asm"