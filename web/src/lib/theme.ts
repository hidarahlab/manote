export type Theme = "light" | "dark";

const THEME_KEY = "manote.theme";

// Dijalankan di <head> sebelum halaman tampil, supaya tema pilihan langsung terpasang dan
// layar tidak berkedip dari terang ke gelap.
export const themeInitScript = `try{var t=localStorage.getItem("${THEME_KEY}");if(t==="light"||t==="dark")document.documentElement.dataset.theme=t}catch(e){}`;

// Tema yang sedang tampil: pilihan pengguna, atau tema perangkat jika belum pernah memilih.
export function currentTheme(): Theme {
  const chosen = document.documentElement.dataset.theme;
  if (chosen === "light" || chosen === "dark") return chosen;
  return window.matchMedia("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

// Pilihan tema disimpan di browser ini, jadi tetap berlaku setelah keluar dan masuk lagi.
export function setTheme(theme: Theme) {
  document.documentElement.dataset.theme = theme;
  try {
    window.localStorage.setItem(THEME_KEY, theme);
  } catch {
    // Penyimpanan browser diblokir: tema tetap berganti untuk kunjungan ini.
  }
}
