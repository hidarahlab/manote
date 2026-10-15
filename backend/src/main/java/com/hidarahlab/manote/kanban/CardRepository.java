package com.hidarahlab.manote.kanban;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CardRepository extends JpaRepository<Card, Long> {

	List<Card> findByBoardIdAndDeletedAtIsNull(Long boardId);

	List<Card> findByBoardIdAndStatusAndDeletedAtIsNullOrderByPositionAsc(Long boardId, CardStatus status);

	@Query("""
			select c from Card c, Board b
			where c.id = :id and b.id = c.boardId and b.ownerId = :ownerId
			and c.deletedAt is null and b.deletedAt is null
			""")
	Optional<Card> findOwned(@Param("id") Long id, @Param("ownerId") Long ownerId);

	/**
	 * Baris berisi: ID papan, status, jumlah kartu.
	 */
	@Query("""
			select c.boardId, c.status, count(c) from Card c
			where c.boardId in :boardIds and c.deletedAt is null
			group by c.boardId, c.status
			""")
	List<Object[]> countByBoardAndStatus(@Param("boardIds") Collection<Long> boardIds);

	/**
	 * Baris berisi: status, jumlah kartu di semua papan milik pengguna.
	 */
	@Query("""
			select c.status, count(c) from Card c, Board b
			where b.id = c.boardId and b.ownerId = :ownerId
			and c.deletedAt is null and b.deletedAt is null
			group by c.status
			""")
	List<Object[]> countByOwnerAndStatus(@Param("ownerId") Long ownerId);

	// Untuk sinkronisasi: termasuk kartu yang sudah dihapus.

	List<Card> findByBoardId(Long boardId);

	@Query("select c from Card c, Board b where b.id = c.boardId and b.ownerId = :ownerId")
	List<Card> findAllOwned(@Param("ownerId") Long ownerId);

	@Query("""
			select c from Card c, Board b
			where b.id = c.boardId and b.ownerId = :ownerId and c.changedAt > :changedAt
			""")
	List<Card> findOwnedChangedAfter(@Param("ownerId") Long ownerId, @Param("changedAt") Instant changedAt);

	@Query("""
			select c from Card c, Board b
			where b.id = c.boardId and b.ownerId = :ownerId and c.clientId in :clientIds
			""")
	List<Card> findOwnedByClientIds(@Param("ownerId") Long ownerId, @Param("clientIds") Collection<UUID> clientIds);

}
