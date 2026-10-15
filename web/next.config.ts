import type { NextConfig } from "next";

// Browser memanggil /api di alamat web itu sendiri, lalu diteruskan ke backend.
// Dengan begitu web bisa dibuka dari alamat mana pun tanpa build ulang dan tanpa CORS.
const backendUrl = process.env.MANOTE_BACKEND_URL ?? "http://localhost:8080";

const nextConfig: NextConfig = {
  // Mode dev (`npm run dev`) hanya melayani berkasnya ke localhost. Alamat lain yang dipakai
  // untuk membuka web ini harus didaftarkan, kalau tidak halamannya berhenti di "Memuat…".
  allowedDevOrigins: ["hidarahlab.local", "*.tailfd11c4.ts.net"],
  async rewrites() {
    return [{ source: "/api/:path*", destination: `${backendUrl}/api/:path*` }];
  },
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
