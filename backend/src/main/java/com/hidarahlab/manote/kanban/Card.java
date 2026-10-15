package com.hidarahlab.manote.kanban;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "cards")
public class Card {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "board_id", nullable = false, updatable = false)
	private Long boardId;

	/**
	 * ID yang dibuat oleh perangkat, supaya kartu bisa dibuat saat offline lalu disinkronkan.
	 */
	@Column(name = "client_id", nullable = false, updatable = false)
	private UUID clientId;

	@Column(nullable = false)
	private String title;

	@Column(nullable = false, columnDefinition = "text")
	private String description;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false)
	private CardStatus status;

	/**
	 * Urutan di dalam kolomnya; yang lebih kecil di atas. Tidak harus berurutan rapat.
	 */
	@Column(nullable = false)
	private int position;

	@Column(name = "note_id", updatable = false)
	private Long noteId;

	/**
	 * Tenggat kartu; kosong berarti tidak ada tenggat.
	 */
	@Column(name = "deadline_at")
	private Instant deadlineAt;

	/**
	 * Kapan kartu masuk ke kolom Done; kosong selama kartu belum selesai.
	 */
	@Column(name = "done_at")
	private Instant doneAt;

	@Column(name = "created_at", nullable = false, updatable = false)
	private Instant createdAt;

	/**
	 * Kapan pengguna terakhir mengubah kartu. Penentu "perubahan terakhir menang".
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

	protected Card() {
	}

	public Card(Long boardId, String title, String description, CardStatus status, int position, Long noteId,
			Instant deadlineAt) {
		this(boardId, UUID.randomUUID(), title, description, status, position, deadlineAt, Board.now());
		this.noteId = noteId;
	}

	public Card(Long boardId, UUID clientId, String title, String description, CardStatus status, int position,
			Instant deadlineAt, Instant updatedAt) {
		this.boardId = boardId;
		this.clientId = clientId;
		this.title = title;
		this.description = description;
		this.status = status;
		this.position = position;
		this.deadlineAt = deadlineAt;
		this.doneAt = (status == CardStatus.DONE) ? updatedAt : null;
		this.createdAt = updatedAt;
		this.updatedAt = updatedAt;
		this.changedAt = Board.now();
	}

	public void update(String title, String description, Instant deadlineAt) {
		this.title = title;
		this.description = description;
		this.deadlineAt = deadlineAt;
		this.updatedAt = Board.now();
		this.changedAt = this.updatedAt;
	}

	/**
	 * Menaruh kartu di kolom dan urutan tertentu. Merapikan urutan saja tidak dihitung sebagai
	 * perubahan oleh pengguna, tetapi tetap dikirim ke perangkat lain saat sinkron.
	 */
	public void place(CardStatus status, int position) {
		if (this.status == status && this.position == position) {
			return;
		}
		if (this.status != status) {
			this.updatedAt = Board.now();
			this.doneAt = (status == CardStatus.DONE) ? this.updatedAt : null;
		}
		this.status = status;
		this.position = position;
		this.changedAt = Board.now();
	}

	public void markDeleted() {
		this.deletedAt = Board.now();
		this.updatedAt = this.deletedAt;
		this.changedAt = this.deletedAt;
	}

	/**
	 * Terapkan perubahan dari perangkat apa adanya, termasuk waktu ubahnya.
	 */
	public void applySync(String title, String description, CardStatus status, int position, Instant deadlineAt,
			Instant doneAt, Instant updatedAt, boolean deleted) {
		this.title = title;
		this.description = description;
		this.doneAt = resolveDoneAt(status, doneAt, updatedAt);
		this.status = status;
		this.position = position;
		this.deadlineAt = deadlineAt;
		this.deletedAt = deleted ? updatedAt : null;
		this.updatedAt = updatedAt;
		this.changedAt = Board.now();
	}

	/**
	 * Perangkat yang tidak mengirim waktu selesai: kartu yang sudah di Done mempertahankan waktunya,
	 * yang baru masuk Done memakai waktu ubahnya.
	 */
	private Instant resolveDoneAt(CardStatus status, Instant doneAt, Instant updatedAt) {
		if (status != CardStatus.DONE) {
			return null;
		}
		if (doneAt != null) {
			return doneAt;
		}
		return (this.status == CardStatus.DONE && this.doneAt != null) ? this.doneAt : updatedAt;
	}

	/**
	 * Waktu selesai yang dikirim perangkat untuk kartu baru.
	 */
	public void setDoneAtFromSync(Instant doneAt) {
		if (this.status == CardStatus.DONE && doneAt != null) {
			this.doneAt = doneAt;
		}
	}

	public boolean isDeleted() {
		return deletedAt != null;
	}

	public Long getId() {
		return id;
	}

	public Long getBoardId() {
		return boardId;
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

	public CardStatus getStatus() {
		return status;
	}

	public int getPosition() {
		return position;
	}

	public Long getNoteId() {
		return noteId;
	}

	public Instant getDeadlineAt() {
		return deadlineAt;
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
