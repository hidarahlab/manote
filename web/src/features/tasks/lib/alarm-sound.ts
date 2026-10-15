// Bunyi alarm di browser. Browser hanya mengizinkan suara setelah pengguna berinteraksi
// dengan halaman, jadi sumber suaranya disiapkan pada klik atau ketukan pertama.
let context: AudioContext | null = null;

function prepare() {
  if (!context) context = new AudioContext();
  if (context.state === "suspended") void context.resume();
}

if (typeof window !== "undefined") {
  window.addEventListener("pointerdown", prepare);
  window.addEventListener("keydown", prepare);
}

function beep() {
  if (!context || context.state !== "running") return;
  const oscillator = context.createOscillator();
  const gain = context.createGain();
  oscillator.type = "square";
  oscillator.frequency.value = 880;
  gain.gain.setValueAtTime(0.15, context.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, context.currentTime + 0.35);
  oscillator.connect(gain).connect(context.destination);
  oscillator.start();
  oscillator.stop(context.currentTime + 0.4);
}

// Mulai berbunyi; mengembalikan fungsi untuk menghentikannya.
export function startAlarmSound(): () => void {
  beep();
  const timer = setInterval(beep, 700);
  return () => clearInterval(timer);
}
