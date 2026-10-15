package com.hidarahlab.manote.task;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Satu tugas: nama dan kapan harus mulai. Alarm di perangkat berbunyi pada waktu mulainya.
 */
@Entity
@Table(name = "tasks")
public class TaskItem {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "owner_id", nullable = false, updatable = false)
	private Long ownerId;

	@Column(name = "client_id", nullable = false, updatable = false)
	private UUID clientId;

	@Column(nullable = false)
	private String title;

	/**
	 * Keterangan tambahan, misalnya isi catatan asal tugas ini.
	 */
	@Column(nullable = false, columnDefinition = "text")
	private String description = "";

	@Column(name = "start_at", nullable = false)
	private Instant startAt;

	/**
	 * Terisi berarti tugas selesai: alarmnya dimatikan atau tugasnya dicentang.
	 */
	@Column(name = "done_at")
	private Instant doneAt;

	@Column(name = "deleted_at")
	private Instant deletedAt;

	@Column(name = "created_at", nullable = false, updatable = false)
	private Instant createdAt;

	/**
	 * Kapan pengguna terakhir mengubah tugas. Penentu "perubahan terakhir menang".
	 */
	@Column(name = "updated_at", nullable = false)
	private Instant updatedAt;

	/**
	 * Kapan baris ini terakhir berubah menurut jam server; penanda sinkron.
	 */
	@Column(name = "changed_at", nullable = false)
	private Instant changedAt;

	protected TaskItem() {
	}

	public TaskItem(Long ownerId, UUID clientId, String title, Instant startAt, Instant updatedAt) {
		this.ownerId = ownerId;
		this.clientId = clientId;
		this.title = title;
		this.startAt = startAt;
		this.createdAt = updatedAt;
		this.updatedAt = updatedAt;
		this.changedAt = now();
	}

	public void update(String title, String description, Instant startAt, boolean done) {
		this.title = title;
		this.description = description;
		this.startAt = startAt;
		if (done && this.doneAt == null) {
			this.doneAt = now();
		}
		else if (!done) {
			this.doneAt = null;
		}
		touch(now());
	}

	public void markDeleted() {
		this.deletedAt = now();
		touch(this.deletedAt);
	}

	/**
	 * Terapkan perubahan dari perangkat apa adanya, termasuk waktu ubahnya.
	 */
	public void applySync(String title, String description, Instant startAt, Instant doneAt, Instant updatedAt,
			boolean deleted) {
		this.title = title;
		this.description = description;
		this.startAt = startAt;
		this.doneAt = doneAt;
		this.deletedAt = deleted ? updatedAt : null;
		touch(updatedAt);
	}

	public boolean isDeleted() {
		return deletedAt != null;
	}

	public boolean isDone() {
		return doneAt != null;
	}

	private void touch(Instant updatedAt) {
		this.updatedAt = updatedAt;
		this.changedAt = now();
	}

	// PostgreSQL menyimpan sampai mikrodetik; disamakan supaya perbandingan waktu konsisten.
	static Instant now() {
		return Instant.now().truncatedTo(ChronoUnit.MICROS);
	}

	public Long getId() {
		return id;
	}

	public UUID getClientId() {
		return clientId;
	}

	public String getTitle() {
		return title;
	}

	public String getDescription() {
		return description;
	}

	public Instant getStartAt() {
		return startAt;
	}

	public Instant getDoneAt() {
		return doneAt;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}

	public Instant getChangedAt() {
		return changedAt;
	}

}
