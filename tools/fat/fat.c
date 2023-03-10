#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "fat.h"

#define ATTR_DIRECTORY 0x10
boot_sector g_bs;
uint8_t* g_fat = NULL;
directory_entry* g_root_dir = NULL;
uint32_t g_root_dir_end;


int read_boot_sector(FILE* disk, boot_sector* bs) {
    if (fread(bs, sizeof(*bs), 1, disk) != 1) {
        if (feof(disk)) {
            return ENODATA;  // End of file or empty file
        } else if (ferror(disk)) {
            return errno;  // Error reading boot sector
        }
    }
    // Verify the boot sector is valid
    if (bs->jmp[0] != 0xEB && bs->jmp[0] != 0xE9) {
        return INVALID_BOOT_SECTOR_ERROR;
    }
    // Verify other fields are valid
    if (bs->bytes_per_sector != SECTOR_SIZE || bs->sectors_per_cluster == 0 || bs->reserved_sectors == 0) {
        return INVALID_BOOT_SECTOR_FIELDS_ERROR;
    }

    return 0;  // Success
}

int read_sectors(FILE* disk, uint32_t lba, uint32_t count, void* buffer) {
    int result = fseek(disk, lba * g_bs.sectors_per_cluster, SEEK_SET);
    if (result != 0) {
        perror("Error seeking to sector");
        return READ_SECTOR_ERROR_SEEK; // error seeking to sector
    }

    uint32_t bytes_read = (uint32_t) fread(buffer, g_bs.bytes_per_sector, count, disk);
    if (bytes_read != count) {
        perror("Error reading sector(s)");
        return READ_SECTOR_ERROR_READ; // error reading sector(s)
    }

    return 0; // success
}

int read_fat(FILE* disk, uint8_t** fat) {
    // Allocate memory for the FAT
    *fat = (uint8_t*) malloc(g_bs.sectors_per_fat * g_bs.bytes_per_sector);
    if (*fat == NULL) {
        return FAT_ALLOCATION_ERROR;
    }

    // Read the FAT from the disk
    int result = read_sectors(disk, g_bs.reserved_sectors, g_bs.sectors_per_fat, *fat);
    if (result != 0) {
        perror("Error reading FAT\n");
        free(*fat);
        *fat = NULL;
        return result;
    }

    return 0; // success
}

int read_root_dir(FILE* disk) {
    // Make sure boot sector has been read
    if (g_bs.bytes_per_sector == 0) {
        perror("Invalid boot sector\n");
        return INVALID_BOOT_SECTOR_ERROR;
    }

    // Calculate the start sector of the root directory
    uint32_t lba = g_bs.reserved_sectors + g_bs.fat_count * g_bs.sectors_per_fat;

    // Calculate the end sector of the root directory
    uint32_t size = g_bs.dir_entries_count * sizeof(directory_entry);
    uint32_t sectors = (size / g_bs.bytes_per_sector) + ((size % g_bs.bytes_per_sector) ? 1 : 0);

    // Allocate memory for root directory
    g_root_dir = (directory_entry*)malloc(sectors * g_bs.bytes_per_sector);
    if (g_root_dir == NULL) {
        return ROOT_DIR_ALLOCATION_ERROR;
    }

    // Read root directory sectors
    int result = read_sectors(disk, lba, sectors, g_root_dir);
    if (result != 0) {
        perror("Error reading root directory\n");
        free(g_root_dir);
        g_root_dir = NULL;
        return result;
    }

    // Store the end sector of the root directory in a global variable
    g_root_dir_end = lba + sectors;

    return 0;
}

directory_entry* find_file(const char* name) {
    // Check if the root directory has been read
    if (g_root_dir == NULL) {
        perror("Root directory has not been read\n");
        return NULL;
    }

    // Check if the FAT has been read
    if (g_fat == NULL) {
        perror("FAT has not been read\n");
        return NULL;
    }

    // Check if the name is valid
    if (name == NULL || strlen(name) == 0) {
        perror("Invalid file name\n");
        return NULL;
    }

    // Check if the name is too long
    if (strlen(name) > 11) {
        perror("File name is too long\n");
        return NULL;
    }

    for (uint32_t i = 0; i < g_bs.dir_entries_count; i++) {
        directory_entry* entry = &g_root_dir[i];

        // Check if the entry is empty
        if (entry->name[0] == 0x00) {
            break;
        }

        // Check if the entry is a file
        if (entry->attributes & ATTR_DIRECTORY) {
            continue;
        }

        // convert name to char array
        char name_arr[12];
        for (int j = 0; j < 11; j++) {
            name_arr[j] = (char) entry->name[j];
        }

        // Check if the name matches
        if (strncmp(name, name_arr, 11) == 0) {
            return entry;
        }
    }

    // File not found
    perror("File not found\n");
    return NULL;
}

int read_file(directory_entry const* entry, FILE* disk, uint8_t* buffer) {
    uint16_t cluster = entry->first_cluster_low;
    uint32_t bytes_remaining = entry->file_size;

    if (cluster == 0) {
        printf("File is empty");
        return 0;
    }

    if (cluster < 2 || cluster >= 0xFF8) {
        perror("Invalid cluster number\n");
        return INVALID_CLUSTER_NUMBER_ERROR;
    }

    if (sizeof buffer < entry->file_size) {
        perror("Buffer is too small\n");
        return BUFFER_TOO_SMALL_ERROR;
    }

    while (cluster < 0xFF8) {  // Stop if end of file or bad cluster
        uint32_t lba = g_root_dir_end + (cluster - 2) * g_bs.sectors_per_cluster;
        uint32_t sector_count = g_bs.sectors_per_cluster;

        // If we don't need a full cluster, adjust the lba count
        if (bytes_remaining < g_bs.bytes_per_sector * g_bs.sectors_per_cluster) {
            sector_count = (bytes_remaining + g_bs.bytes_per_sector - 1) / g_bs.bytes_per_sector;
        }

        int result = read_sectors(disk, lba, sector_count, buffer);
        if (result < 0) {
            fprintf(stderr, "Failed to read lba %d (count %d)\n", lba, sector_count);
            return result;
        }

        bytes_remaining -= sector_count * g_bs.bytes_per_sector;
        buffer += sector_count * g_bs.bytes_per_sector;

        // Get the next cluster
        uint32_t fat_index = cluster * 3 / 2; // This is because of the stupidness of 12-bits
        if (cluster % 2 == 0) {
            cluster = g_fat[fat_index] & 0x0FFF;
        } else {
            cluster = g_fat[fat_index + 1] >> 4;
        }

        if (bytes_remaining == 0) {
            break;
        }
    }

    return 0;
}


int main(int argc, char** argv) {
    if (argc < 3) {
        printf("Syntax: %s <disk image> <file_entry name>\n", argv[0]);
        return EXIT_FAILURE;
    }

    // Open the disk image
    FILE* disk = fopen(argv[1], "rb");
    if (disk == NULL) {
        perror("Error opening disk image");
        return EXIT_FAILURE;
    }

    // Read the boot sector
    if (read_boot_sector(disk, &g_bs) != 0) {
        perror("Error reading boot sector");
        fclose(disk);
        return EXIT_FAILURE;
    }

    // Read the FAT
    if (read_fat(disk, &g_fat) != 0) {
        perror("Error reading FAT");
        fclose(disk);
        return EXIT_FAILURE;
    }

    // Read the root directory
    if (read_root_dir(disk) != 0) {
        perror("Error reading root directory");
        free(g_fat);
        fclose(disk);
        return EXIT_FAILURE;
    }

    // Find the file entry
    directory_entry const* entry = find_file(argv[2]);
    if (entry == NULL) {
        perror("Error finding file entry");
        free(g_root_dir);
        free(g_fat);
        fclose(disk);
        return EXIT_FAILURE;
    }

    // Allocate memory for the file
    uint8_t* file = (uint8_t*)malloc(entry->file_size);
    if (file == NULL) {
        perror("Error allocating memory for file");
        free(g_root_dir);
        free(g_fat);
        fclose(disk);
        return EXIT_FAILURE;
    }

    // Read the file
    if (read_file(entry, disk, file) != 0) {
        perror("Error reading file");
        free(file);
        free(g_root_dir);
        free(g_fat);
        fclose(disk);
        return EXIT_FAILURE;
    }

    // Print the contents of the file.
    // Loop through the file bytes and print them as characters if they are printable. Print this a <hex> if they are not.
    for (uint32_t i = 0; i < entry->file_size; i++) {
        if (isprint(file[i])) {
            printf("%c", file[i]);
        } else {
            printf("<%02X>", file[i]);
        }
    }

    // Free the memory
    free(file);
    free(g_root_dir);
    free(g_fat);
    fclose(disk);

    return EXIT_SUCCESS;
}
