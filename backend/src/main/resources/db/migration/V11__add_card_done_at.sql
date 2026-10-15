-- Kapan kartu masuk ke kolom Done; kosong selama kartu belum selesai.
ALTER TABLE cards ADD COLUMN done_at TIMESTAMPTZ;
UPDATE cards SET done_at = updated_at WHERE status = 'DONE';
