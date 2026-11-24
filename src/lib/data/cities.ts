// Offline presets for prayer-time settings. Coordinates are city-centre
// approximations; users can enter exact coordinates when they need to.

export interface City {
  id: string;
  name: string;
  nameEn: string;
  country: string;
  latitude: number;
  longitude: number;
  timezone: string;
}

export const cities: City[] = [
  { id: "makkah", name: "مكة المكرمة", nameEn: "Makkah", country: "السعودية", latitude: 21.4225, longitude: 39.8262, timezone: "Asia/Riyadh" },
  { id: "madinah", name: "المدينة المنورة", nameEn: "Madinah", country: "السعودية", latitude: 24.4686, longitude: 39.6142, timezone: "Asia/Riyadh" },
  { id: "riyadh", name: "الرياض", nameEn: "Riyadh", country: "السعودية", latitude: 24.7136, longitude: 46.6753, timezone: "Asia/Riyadh" },
  { id: "jeddah", name: "جدة", nameEn: "Jeddah", country: "السعودية", latitude: 21.4858, longitude: 39.1925, timezone: "Asia/Riyadh" },
  { id: "dammam", name: "الدمام", nameEn: "Dammam", country: "السعودية", latitude: 26.4207, longitude: 50.0888, timezone: "Asia/Riyadh" },
  { id: "cairo", name: "القاهرة", nameEn: "Cairo", country: "مصر", latitude: 30.0444, longitude: 31.2357, timezone: "Africa/Cairo" },
  { id: "alexandria", name: "الإسكندرية", nameEn: "Alexandria", country: "مصر", latitude: 31.2001, longitude: 29.9187, timezone: "Africa/Cairo" },
  { id: "khartoum", name: "الخرطوم", nameEn: "Khartoum", country: "السودان", latitude: 15.5007, longitude: 32.5599, timezone: "Africa/Khartoum" },
  { id: "amman", name: "عمّان", nameEn: "Amman", country: "الأردن", latitude: 31.9539, longitude: 35.9106, timezone: "Asia/Amman" },
  { id: "jerusalem", name: "القدس", nameEn: "Jerusalem", country: "فلسطين", latitude: 31.7683, longitude: 35.2137, timezone: "Asia/Jerusalem" },
  { id: "gaza", name: "غزة", nameEn: "Gaza", country: "فلسطين", latitude: 31.5017, longitude: 34.4668, timezone: "Asia/Gaza" },
  { id: "damascus", name: "دمشق", nameEn: "Damascus", country: "سوريا", latitude: 33.5138, longitude: 36.2765, timezone: "Asia/Damascus" },
  { id: "baghdad", name: "بغداد", nameEn: "Baghdad", country: "العراق", latitude: 33.3152, longitude: 44.3661, timezone: "Asia/Baghdad" },
  { id: "beirut", name: "بيروت", nameEn: "Beirut", country: "لبنان", latitude: 33.8938, longitude: 35.5018, timezone: "Asia/Beirut" },
  { id: "dubai", name: "دبي", nameEn: "Dubai", country: "الإمارات", latitude: 25.2048, longitude: 55.2708, timezone: "Asia/Dubai" },
  { id: "doha", name: "الدوحة", nameEn: "Doha", country: "قطر", latitude: 25.2854, longitude: 51.531, timezone: "Asia/Qatar" },
  { id: "kuwait", name: "الكويت", nameEn: "Kuwait City", country: "الكويت", latitude: 29.3759, longitude: 47.9774, timezone: "Asia/Kuwait" },
  { id: "manama", name: "المنامة", nameEn: "Manama", country: "البحرين", latitude: 26.2285, longitude: 50.586, timezone: "Asia/Bahrain" },
  { id: "muscat", name: "مسقط", nameEn: "Muscat", country: "عمان", latitude: 23.588, longitude: 58.3829, timezone: "Asia/Muscat" },
  { id: "sanaa", name: "صنعاء", nameEn: "Sanaa", country: "اليمن", latitude: 15.3694, longitude: 44.191, timezone: "Asia/Aden" },
  { id: "tripoli", name: "طرابلس", nameEn: "Tripoli", country: "ليبيا", latitude: 32.8872, longitude: 13.1913, timezone: "Africa/Tripoli" },
  { id: "tunis", name: "تونس", nameEn: "Tunis", country: "تونس", latitude: 36.8065, longitude: 10.1815, timezone: "Africa/Tunis" },
  { id: "algiers", name: "الجزائر", nameEn: "Algiers", country: "الجزائر", latitude: 36.7538, longitude: 3.0588, timezone: "Africa/Algiers" },
  { id: "rabat", name: "الرباط", nameEn: "Rabat", country: "المغرب", latitude: 34.0209, longitude: -6.8416, timezone: "Africa/Casablanca" },
  { id: "nouakchott", name: "نواكشوط", nameEn: "Nouakchott", country: "موريتانيا", latitude: 18.0735, longitude: -15.9582, timezone: "Africa/Nouakchott" },
  { id: "mogadishu", name: "مقديشو", nameEn: "Mogadishu", country: "الصومال", latitude: 2.0469, longitude: 45.3182, timezone: "Africa/Mogadishu" },
  { id: "istanbul", name: "إستانبول", nameEn: "Istanbul", country: "تركيا", latitude: 41.0082, longitude: 28.9784, timezone: "Europe/Istanbul" },
  { id: "london", name: "لندن", nameEn: "London", country: "المملكة المتحدة", latitude: 51.5074, longitude: -0.1278, timezone: "Europe/London" },
  { id: "paris", name: "باريس", nameEn: "Paris", country: "فرنسا", latitude: 48.8566, longitude: 2.3522, timezone: "Europe/Paris" },
  { id: "berlin", name: "برلين", nameEn: "Berlin", country: "ألمانيا", latitude: 52.52, longitude: 13.405, timezone: "Europe/Berlin" },
  { id: "newyork", name: "نيويورك", nameEn: "New York", country: "الولايات المتحدة", latitude: 40.7128, longitude: -74.0059, timezone: "America/New_York" },
  { id: "toronto", name: "تورونتو", nameEn: "Toronto", country: "كندا", latitude: 43.6532, longitude: -79.3832, timezone: "America/Toronto" },
  { id: "kualalumpur", name: "كوالالمبور", nameEn: "Kuala Lumpur", country: "ماليزيا", latitude: 3.139, longitude: 101.6869, timezone: "Asia/Kuala_Lumpur" },
  { id: "jakarta", name: "جاكرتا", nameEn: "Jakarta", country: "إندونيسيا", latitude: -6.2088, longitude: 106.8456, timezone: "Asia/Jakarta" },
  { id: "sydney", name: "سيدني", nameEn: "Sydney", country: "أستراليا", latitude: -33.8688, longitude: 151.2093, timezone: "Australia/Sydney" },
];

/** Timezones worth offering beyond the city list, kept unique and sorted. */
export const timezones: string[] = [
  ...new Set([...cities.map((city) => city.timezone), "UTC"]),
].sort();

/** Closest preset for a coordinate pair, or null when none is close enough. */
export function nearestCity(latitude: number, longitude: number): City | null {
  let best: { city: City; distance: number } | null = null;
  for (const city of cities) {
    const dLat = city.latitude - latitude;
    const dLon = (city.longitude - longitude) * Math.cos((latitude * Math.PI) / 180);
    const distance = dLat * dLat + dLon * dLon;
    if (!best || distance < best.distance) best = { city, distance };
  }
  return best && Math.sqrt(best.distance) < 0.35 ? best.city : null;
}
