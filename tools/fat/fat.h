#include <stdint.h>
#include <stdio.h>

#define SECTOR_SIZE 512

// Error codes for read_boot_sector() function
#define READ_BOOT_SECTOR_ERROR -1
#define INVALID_BOOT_SECTOR_ERROR -2
#define INVALID_BOOT_SECTOR_FIELDS_ERROR -3

// Error codes for read_sectors() function
#define READ_SECTOR_ERROR_SEEK -4
#define READ_SECTOR_ERROR_READ -5

// Error codes for read_fat() function
#define FAT_ALLOCATION_ERROR -6
#define FAT_READ_ERROR_SEEK -7
#define FAT_READ_ERROR_READ -8

// Error codes for read_root_dir() function
#define ROOT_DIR_ALLOCATION_ERROR -9

// Error codes for read_file() function
#define INVALID_CLUSTER_NUMBER_ERROR -10
#define BUFFER_TOO_SMALL_ERROR -11

/**
 * @brief Boot sector of a FAT12 file system
 */
typedef struct {
    u_int8_t jmp[3];                   // Jump instruction
    u_int8_t oem[8];                   // OEM name and version
    u_int16_t bytes_per_sector;        // Bytes per sector
    u_int8_t sectors_per_cluster;      // Sectors per cluster
    u_int16_t reserved_sectors;        // Number of reserved sectors
    u_int8_t fat_count;                // Number of File Allocation Tables
    u_int16_t dir_entries_count;       // Number of directory entries in the root directory
    u_int16_t total_sectors;           // Total number of sectors on the disk
    u_int8_t media_descriptor_type;    // Type of media descriptor
    u_int16_t sectors_per_fat;         // Sectors per File Allocation Table
    u_int16_t sectors_per_track;       // Sectors per track
    u_int16_t head_count;              // Number of heads
    u_int32_t hidden_sectors;          // Number of hidden sectors
    u_int32_t large_sector_count;      // Total number of sectors (if total_sectors == 0)

    // Extended Boot Record (EBR)
    u_int8_t drive_number;             // BIOS drive number
    u_int8_t reserved;                 // Reserved for Windows NT
    u_int8_t signature;                // Signature of the volume
    u_int32_t volume_id;               // Volume serial number
    u_int8_t volume_label[11];         // Volume label
    u_int8_t system_id[8];             // File system type
} __attribute__((packed)) boot_sector;

/**
 * @brief Directory entry of a FAT12 file system
 */
typedef struct {
    u_int8_t name[11];                 // Name of the file
    u_int8_t attributes;               // File attributes
    u_int8_t reserved;                 // Reserved for Windows NT
    u_int8_t creation_time_tenths;     // Creation time in tenths of a second
    u_int16_t creation_time;           // Creation time
    u_int16_t creation_date;           // Creation date
    u_int16_t last_access_date;        // Last access date
    u_int16_t first_cluster_high;      // High word of first cluster number
    u_int16_t last_modification_time;  // Last modification time
    u_int16_t last_modification_date;  // Last modification date
    u_int16_t first_cluster_low;       // Low word of first cluster number
    u_int32_t file_size;               // File size in bytes
} __attribute__((packed)) directory_entry;

/**
 * Read the boot sector of a FAT12 file system
 * @param disk the file descriptor of the disk
 * @param bs the boot sector struct to fill
 * @return 0 on success, a negative error code on failure
 */
int read_boot_sector(FILE* disk, boot_sector* bs);

/**
 * Read FAT12 sectors from a disk
 * @param disk The disk to read from
 * @param sector The sector to start reading from
 * @param count The number of sectors to read
 * @param buffer The buffer to read into
 * @return 0 on success, a negative error code on failure
 */
int read_sectors(FILE* disk, u_int32_t sector, u_int32_t count, void* buffer);

/**
 * Read the FAT table of a FAT12 file system
 * @param disk The disk to read from
 * @param fat The buffer to read into
 * @return 0 on success, a negative error code on failure
 */
int read_fat(FILE* disk, u_int8_t** fat);

/**
 * Read the root directory of a FAT12 file system
 * @param disk The disk to read from
 * @return 0 on success, a negative error code on failure
 */
int read_root_dir(FILE* disk);

/**
 * Find a file in the root directory
 * @param name The name of the file to find
 * @return NULL if the file was not found, a pointer to the directory entry otherwise
 */
directory_entry* find_file(const char* name);

/**
 * Read a file from a FAT12 file system
 * @param entry The directory entry of the file to read
 * @param disk The disk to read from
 * @param buffer The buffer to read into
 * @return The number of bytes read on success, a negative error code on failure
 */
int read_file(directory_entry const* entry, FILE* disk, u_int8_t* buffer);