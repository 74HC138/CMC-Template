    defc FAT_BLOCKSIZE = 512
    defc FAT_DISPLAY_VOLUMESTRING = 1
    defc FAT_DISPLAY_VOLUMEID = 1

    dsect
FAT:
    .pReadFunction:
        dc 2
    .pWriteFunction:
        dc 2
    .dataBuffer:
        dc FAT_BLOCKSIZE
    dend

;Initializes FAT driver
;Parameters:
;(void readFunction)(uint16_t LBA, uint8_t* buffer)
;(void writeFunction)(uint16_t LBA, uint8_t* buffer)
;Returns:
;0: succes
;>0: error
FAT.init:
        DSPeekBC 0
        ld (.pWriteFunction), bc
        DSPeekBC 2
        cpBCNN 0x0000
        ld a, 0x01
        ret z ;return 0x01 when no read function is given
        ld (.pReadFunction), bc

        ;read first block
        DSPushNN 0x0000
        DSPushNN .dataBuffer
        callNNin .pReadFunction
        DSRestore 4
        ld iy, .dataBuffer

        ;check signature
        ld a, (iy+38)
        cp 0x28
        jr z, .initSignatureOK
        cp 0x29
        jr z, .initSignatureOK
        ld a, 0x02
        ret ;return 0x02 if signature check failed -> this is not fat12/16
    .initSignatureOK:

    if FAT_DISPLAY_VOLUMESTRING
        ;display the volume string if flag is set
        DSPushNN .initVolumeStringPrefix
        call Serial1.puts
        DSRestore 2
        ld hl, .dataBuffer
        ld bc, 0x002b
        add hl, bc
        ld d, 11
    .initDisplayStringLoop:
        ld a, (hl)
        DSPush a
        call Serial1.putc
        DSRestore 1
        inc hl
        dec d
        ld a, 0x00
        cp d
        jr nz, .initDisplayStringLoop
        ld a, '\n'
        DSPush a
        call Serial1.putc
        DSRestore 1
    endif
    if FAT_DISPLAY_VOLUMEID
        ;display the volume ID if flag is set
        DSPushNN .initVolumeIDPrefix
        call Serial1.puts
        DSRestore 2
        ld hl, .dataBuffer
        ld bc, 0x002a
        add hl, bc
        repeat 4
            ld a, (hl)
            dec hl
            DSPush a
        endrepeat
        call stdio.putu32h
        DSRestore 4
        ld a, '\n'
        DSPush a
        call Serial1.putc
        DSRestore 1
    endif

        ld a, 0x00
        ret



    .initVolumeStringPrefix:
        string "Volume Label:"
    .initVolumeIDPrefix:
        string "Volume ID:"


