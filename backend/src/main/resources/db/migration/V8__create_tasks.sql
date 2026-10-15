CREATE TABLE tasks (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id   BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- ID yang dibuat perangkat, supaya tugas bisa dibuat saat offline lalu disinkronkan.
    client_id  UUID         NOT NULL DEFAULT gen_random_uuid(),
    title      VARCHAR(255) NOT NULL,
    -- Kapan tugas harus mulai; alarm berbunyi pada waktu ini.
    start_at   TIMESTAMPTZ  NOT NULL,
    -- Terisi berarti tugas selesai (alarmnya dimatikan atau dicentang).
    done_at    TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL,
    updated_at TIMESTAMPTZ  NOT NULL,
    changed_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT tasks_owner_client_id_key UNIQUE (owner_id, client_id)
);

CREATE INDEX tasks_owner_changed_idx ON tasks (owner_id, changed_at);
CREATE INDEX tasks_owner_start_idx ON tasks (owner_id, start_at);
