;
; FAT12 header
;
bdb_oem: db 'MSWIN4.1'   ; 8 bytes
bdb_bytes_per_sector: dw 512
bdb_sectors_per_cluster: db 1
bdb_reserved_sectors: dw 1
bdb_fat_count: db 2
bdb_dir_entries_count: dw 0E0h
bdb_total_sectors: dw 2880
bdb_media_descriptor_type: db 0F0h
bdb_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sector_count: dd 0

; extended boot record
ebr_drive_number: db 0
                  db 0
ebr_signature:    db 29h
ebr_volume_id:    db 12h, 34h, 56h, 78h
ebr_volume_label: db 'BSOS       '
ebr_system_id:    db 'FAT12   '