package com.hidarahlab.manote.note;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "notes")
public class Note {

	private static final int DISPLAY_TITLE_LENGTH = 60;

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "owner_id", nullable = false, updatable = false)
	private Long ownerId;

	/**
	 * ID yang dibuat oleh perangkat, supaya catatan bisa dibuat saat offline lalu
	 * disinkronkan.
	 */
	@Column(name = "client_id", nullable = false, updatable = false)
	private UUID clientId;

	@Column(nullable = false)
	private String title;

	@Column(nullable = false, columnDefinition = "text")
	private String content;

	@Column(name = "created_at", nullable = false, updatable = false)
	private Instant createdAt;

	/**
	 * Kapan pengguna terakhir mengubah catatan. Penentu "perubahan terakhir menang".
	 */
	@Column(name = "updated_at", nullable = false)
	private Instant updatedAt;

	@Column(name = "reminder_at")
	private Instant reminderAt;

	/**
	 * Terisi berarti catatan sudah dihapus. Barisnya disimpan supaya perangkat lain tahu
	 * harus ikut menghapus.
	 */
	@Column(name = "deleted_at")
	private Instant deletedAt;

	/**
	 * Kapan baris ini terakhir berubah menurut jam server. Dipakai sebagai penanda
	 * "perubahan sejak sinkron terakhir".
	 */
	@Column(name = "changed_at", nullable = false)
	private Instant changedAt;

	protected Note() {
	}

	public Note(Long ownerId, String title, String content) {
		this(ownerId, UUID.randomUUID(), title, content, now());
	}

	public Note(Long ownerId, UUID clientId, String title, String content, Instant updatedAt) {
		this.ownerId = ownerId;
		this.clientId = clientId;
		this.title = title;
		this.content = content;
		this.createdAt = updatedAt;
		this.updatedAt = updatedAt;
		this.changedAt = now();
	}

	public void update(String title, String content) {
		this.title = title;
		this.content = content;
		touch(now());
	}

	public void setReminderAt(Instant reminderAt) {
		this.reminderAt = reminderAt;
		touch(now());
	}

	public void markDeleted() {
		this.deletedAt = now();
		touch(this.deletedAt);
	}

	/**
	 * Terapkan perubahan dari perangkat apa adanya, termasuk waktu ubahnya.
	 */
	public void applySync(String title, String content, Instant reminderAt, Instant updatedAt, boolean deleted) {
		this.title = title;
		this.content = content;
		this.reminderAt = reminderAt;
		this.deletedAt = deleted ? updatedAt : null;
		touch(updatedAt);
	}

	public boolean isDeleted() {
		return deletedAt != null;
	}

	private void touch(Instant updatedAt) {
		this.updatedAt = updatedAt;
		this.changedAt = now();
	}

	// PostgreSQL menyimpan sampai mikrodetik; disamakan supaya perbandingan waktu konsisten.
	static Instant now() {
		return Instant.now().truncatedTo(ChronoUnit.MICROS);
	}

	/**
	 * Judul untuk ditampilkan: judul catatan, atau baris pertama isinya jika judul kosong.
	 */
	public String displayTitle() {
		if (!title.isBlank()) {
			return title.strip();
		}
		String firstLine = content.strip().lines().findFirst().orElse("");
		if (firstLine.isBlank()) {
			return "Tanpa judul";
		}
		return (firstLine.length() > DISPLAY_TITLE_LENGTH) ? firstLine.substring(0, DISPLAY_TITLE_LENGTH) + "…"
				: firstLine;
	}

	public Long getId() {
		return id;
	}

	public Long getOwnerId() {
		return ownerId;
	}

	public UUID getClientId() {
		return clientId;
	}

	public String getTitle() {
		return title;
	}

	public String getContent() {
		return content;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}

	public Instant getReminderAt() {
		return reminderAt;
	}

	public Instant getChangedAt() {
		return changedAt;
	}

}
