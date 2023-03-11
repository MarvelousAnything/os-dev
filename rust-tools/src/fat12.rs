use std::{fs::File, io::BufWriter};

#[repr(packed)]
pub struct BootSector {
    pub jmp: [u8; 3],
    pub oem: [u8; 8],
    pub bytes_per_sector: u16,
    pub sectors_per_cluster: u8,
    pub reserved_sectors: u16,
    pub fat_count: u8,
    pub dir_entries_count: u16,
    pub total_sectors: u16,
    pub media_descriptor_type: u8,
    pub sectors_per_fat: u16,
    pub sectors_per_track: u16,
    pub head_count: u16,
    pub hidden_sectors: u32,
    pub large_sector_count: u32,
    // EBR
    pub drive_number: u8,
    pub reserved: u8,
    pub signature: u8,
    pub volume_id: u32,
    pub volume_label: [u8; 11],
    pub system_id: [u8; 8],
}

#[repr(packed)]
pub struct DirectorEntry {
    pub name: [u8; 11],
    pub attributes: u8,
    pub reserved: u8,
    pub creation_time_tenths: u8,
    pub creation_time: u16,
    pub creation_date: u16,
    pub last_access_date: u16,
    pub first_cluster_high: u16,
    pub last_modification_time: u16,
    pub last_modification_date: u16,
    pub first_cluster_low: u16,
    pub file_size: u32,
}

pub trait FileSystem {
    fn read_boot_sector(&self) -> BootSector;
    fn read_sectors(self, lba: u32, count: u32);
}
