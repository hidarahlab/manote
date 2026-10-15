-- Keterangan tugas, misalnya isi catatan asalnya.
ALTER TABLE tasks ADD COLUMN description TEXT NOT NULL DEFAULT '';
