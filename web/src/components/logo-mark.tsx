// Logo Manote: selembar kertas dengan tiga garis berwarna.
export function LogoMark({ size = 64 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden="true">
      <rect width="100" height="100" rx="28" fill="#534AB7" />
      <rect x="22" y="22" width="56" height="56" rx="10" fill="#FFFFFF" />
      <rect x="32" y="33" width="36" height="6.5" rx="3.25" fill="#EF9F27" />
      <rect x="32" y="47" width="28" height="6.5" rx="3.25" fill="#1D9E75" />
      <rect x="32" y="61" width="20" height="6.5" rx="3.25" fill="#D85A30" />
    </svg>
  );
}
