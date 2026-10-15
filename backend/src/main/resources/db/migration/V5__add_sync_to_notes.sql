-- Sinkronisasi: ID yang bisa dibuat di perangkat, tanda terhapus, dan waktu perubahan di server.
ALTER TABLE notes ADD COLUMN client_id UUID NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE notes ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE notes ADD COLUMN changed_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE notes ADD CONSTRAINT notes_owner_client_id_key UNIQUE (owner_id, client_id);
CREATE INDEX notes_owner_changed_idx ON notes (owner_id, changed_at);
