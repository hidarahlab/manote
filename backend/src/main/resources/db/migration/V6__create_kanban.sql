CREATE TABLE boards (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id   BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL,
    updated_at TIMESTAMPTZ  NOT NULL
);

CREATE INDEX boards_owner_updated_idx ON boards (owner_id, updated_at DESC);

CREATE TABLE cards (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    board_id    BIGINT       NOT NULL REFERENCES boards (id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    description TEXT         NOT NULL DEFAULT '',
    status      VARCHAR(20)  NOT NULL,
    position    INTEGER      NOT NULL,
    -- Catatan asal kartu ini, jika dibuat dari catatan.
    note_id     BIGINT REFERENCES notes (id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ  NOT NULL,
    updated_at  TIMESTAMPTZ  NOT NULL
);

CREATE INDEX cards_board_status_position_idx ON cards (board_id, status, position);
