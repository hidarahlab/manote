package com.hidarahlab.manote.common;

/**
 * Bentuk semua response API, sukses maupun gagal.
 *
 * @param status {@code true} jika berhasil
 * @param title pesan yang siap ditampilkan ke pengguna
 * @param code kode HTTP standar atau kode khusus Manote (lihat {@link ErrorCode})
 * @param data hasilnya; {@code null} jika gagal atau memang tidak ada isi
 */
public record ApiResponse<T>(boolean status, String title, int code, T data) {

	private static final String SUCCESS_TITLE = "Berhasil";

	public static <T> ApiResponse<T> ok(T data) {
		return new ApiResponse<>(true, SUCCESS_TITLE, 200, data);
	}

	public static ApiResponse<Void> ok() {
		return new ApiResponse<>(true, SUCCESS_TITLE, 200, null);
	}

	public static <T> ApiResponse<T> created(T data) {
		return new ApiResponse<>(true, SUCCESS_TITLE, 201, data);
	}

	public static ApiResponse<Void> error(int code, String title) {
		return new ApiResponse<>(false, title, code, null);
	}

}
