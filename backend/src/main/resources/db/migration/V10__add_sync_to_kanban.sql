-- Sinkronisasi kerjaan: ID yang bisa dibuat di perangkat, tanda terhapus, dan waktu perubahan di server.
ALTER TABLE boards ADD COLUMN client_id UUID NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE boards ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE boards ADD COLUMN changed_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE boards ADD CONSTRAINT boards_owner_client_id_key UNIQUE (owner_id, client_id);
CREATE INDEX boards_owner_changed_idx ON boards (owner_id, changed_at);

ALTER TABLE cards ADD COLUMN client_id UUID NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE cards ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE cards ADD COLUMN changed_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE cards ADD CONSTRAINT cards_board_client_id_key UNIQUE (board_id, client_id);
CREATE INDEX cards_changed_idx ON cards (changed_at);
