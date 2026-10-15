package com.hidarahlab.manote.kanban;

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
 * Satu "kerjaan": papan kanban berisi kartu-kartu.
 */
@Entity
@Table(name = "boards")
public class Board {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "owner_id", nullable = false, updatable = false)
	private Long ownerId;

	/**
	 * ID yang dibuat oleh perangkat, supaya kerjaan bisa dibuat saat offline lalu disinkronkan.
	 */
	@Column(name = "client_id", nullable = false, updatable = false)
	private UUID clientId;

	@Column(nullable = false)
	private String name;

	@Column(name = "created_at", nullable = false, updatable = false)
	private Instant createdAt;

	/**
	 * Kapan kerjaan atau isinya terakhir diubah. Penentu "perubahan terakhir menang" dan
	 * urutan daftar.
	 */
	@Column(name = "updated_at", nullable = false)
	private Instant updatedAt;

	@Column(name = "deleted_at")
	private Instant deletedAt;

	/**
	 * Kapan baris ini terakhir berubah menurut jam server; penanda sinkron.
	 */
	@Column(name = "changed_at", nullable = false)
	private Instant changedAt;

	protected Board() {
	}

	public Board(Long ownerId, String name) {
		this(ownerId, UUID.randomUUID(), name, now());
	}

	public Board(Long ownerId, UUID clientId, String name, Instant updatedAt) {
		this.ownerId = ownerId;
		this.clientId = clientId;
		this.name = name;
		this.createdAt = updatedAt;
		this.updatedAt = updatedAt;
		this.changedAt = now();
	}

	public void rename(String name) {
		this.name = name;
		touch();
	}

	/**
	 * Dipanggil setiap isi papan berubah, supaya papan yang baru dipakai naik ke atas daftar.
	 */
	public void touch() {
		this.updatedAt = now();
		this.changedAt = this.updatedAt;
	}

	public void markDeleted() {
		this.deletedAt = now();
		touch();
	}

	/**
	 * Terapkan perubahan dari perangkat apa adanya, termasuk waktu ubahnya.
	 */
	public void applySync(String name, Instant updatedAt, boolean deleted) {
		this.name = name;
		this.deletedAt = deleted ? updatedAt : null;
		this.updatedAt = updatedAt;
		this.changedAt = now();
	}

	public boolean isDeleted() {
		return deletedAt != null;
	}

	// PostgreSQL menyimpan sampai mikrodetik; disamakan supaya perbandingan waktu konsisten.
	static Instant now() {
		return Instant.now().truncatedTo(ChronoUnit.MICROS);
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

	public String getName() {
		return name;
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
