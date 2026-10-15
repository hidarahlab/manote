-- Password disimpan sebagai hash BCrypt, bukan teks asli.
INSERT INTO users (user_id, email, password_hash, full_name, user_type)
VALUES ('hidarah96', 'hidarah96@gmail.com', '$2y$10$FGVfLvC.HxSUkxeY5UvcP.HGDfKTmS9fREKDHew.qJF9q/pv3y/JW', 'Rahmad Hidayat', 'USER');
