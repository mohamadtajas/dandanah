// Offline presets for prayer-time settings. Coordinates are city-centre
// approximations; users can enter exact coordinates when they need to.

export interface City {
  id: string;
  name: string;
  nameEn: string;
  country: string;
  countryEn: string;
  latitude: number;
  longitude: number;
  timezone: string;
}

export const cities: City[] = [
  { id: "makkah", name: "مكة المكرمة", nameEn: "Makkah", country: "السعودية", countryEn: "Saudi Arabia", latitude: 21.4225, longitude: 39.8262, timezone: "Asia/Riyadh" },
  { id: "madinah", name: "المدينة المنورة", nameEn: "Madinah", country: "السعودية", countryEn: "Saudi Arabia", latitude: 24.4686, longitude: 39.6142, timezone: "Asia/Riyadh" },
  { id: "riyadh", name: "الرياض", nameEn: "Riyadh", country: "السعودية", countryEn: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753, timezone: "Asia/Riyadh" },
  { id: "jeddah", name: "جدة", nameEn: "Jeddah", country: "السعودية", countryEn: "Saudi Arabia", latitude: 21.4858, longitude: 39.1925, timezone: "Asia/Riyadh" },
  { id: "dammam", name: "الدمام", nameEn: "Dammam", country: "السعودية", countryEn: "Saudi Arabia", latitude: 26.4207, longitude: 50.0888, timezone: "Asia/Riyadh" },
  { id: "cairo", name: "القاهرة", nameEn: "Cairo", country: "مصر", countryEn: "Egypt", latitude: 30.0444, longitude: 31.2357, timezone: "Africa/Cairo" },
  { id: "alexandria", name: "الإسكندرية", nameEn: "Alexandria", country: "مصر", countryEn: "Egypt", latitude: 31.2001, longitude: 29.9187, timezone: "Africa/Cairo" },
  { id: "khartoum", name: "الخرطوم", nameEn: "Khartoum", country: "السودان", countryEn: "Sudan", latitude: 15.5007, longitude: 32.5599, timezone: "Africa/Khartoum" },
  { id: "amman", name: "عمّان", nameEn: "Amman", country: "الأردن", countryEn: "Jordan", latitude: 31.9539, longitude: 35.9106, timezone: "Asia/Amman" },
  { id: "jerusalem", name: "القدس", nameEn: "Jerusalem", country: "فلسطين", countryEn: "Palestine", latitude: 31.7683, longitude: 35.2137, timezone: "Asia/Jerusalem" },
  { id: "gaza", name: "غزة", nameEn: "Gaza", country: "فلسطين", countryEn: "Palestine", latitude: 31.5017, longitude: 34.4668, timezone: "Asia/Gaza" },
  { id: "damascus", name: "دمشق", nameEn: "Damascus", country: "سوريا", countryEn: "Syria", latitude: 33.5138, longitude: 36.2765, timezone: "Asia/Damascus" },
  { id: "baghdad", name: "بغداد", nameEn: "Baghdad", country: "العراق", countryEn: "Iraq", latitude: 33.3152, longitude: 44.3661, timezone: "Asia/Baghdad" },
  { id: "beirut", name: "بيروت", nameEn: "Beirut", country: "لبنان", countryEn: "Lebanon", latitude: 33.8938, longitude: 35.5018, timezone: "Asia/Beirut" },
  { id: "dubai", name: "دبي", nameEn: "Dubai", country: "الإمارات", countryEn: "United Arab Emirates", latitude: 25.2048, longitude: 55.2708, timezone: "Asia/Dubai" },
  { id: "doha", name: "الدوحة", nameEn: "Doha", country: "قطر", countryEn: "Qatar", latitude: 25.2854, longitude: 51.531, timezone: "Asia/Qatar" },
  { id: "kuwait", name: "الكويت", nameEn: "Kuwait City", country: "الكويت", countryEn: "Kuwait", latitude: 29.3759, longitude: 47.9774, timezone: "Asia/Kuwait" },
  { id: "manama", name: "المنامة", nameEn: "Manama", country: "البحرين", countryEn: "Bahrain", latitude: 26.2285, longitude: 50.586, timezone: "Asia/Bahrain" },
  { id: "muscat", name: "مسقط", nameEn: "Muscat", country: "عمان", countryEn: "Oman", latitude: 23.588, longitude: 58.3829, timezone: "Asia/Muscat" },
  { id: "sanaa", name: "صنعاء", nameEn: "Sanaa", country: "اليمن", countryEn: "Yemen", latitude: 15.3694, longitude: 44.191, timezone: "Asia/Aden" },
  { id: "tripoli", name: "طرابلس", nameEn: "Tripoli", country: "ليبيا", countryEn: "Libya", latitude: 32.8872, longitude: 13.1913, timezone: "Africa/Tripoli" },
  { id: "tunis", name: "تونس", nameEn: "Tunis", country: "تونس", countryEn: "Tunisia", latitude: 36.8065, longitude: 10.1815, timezone: "Africa/Tunis" },
  { id: "algiers", name: "الجزائر", nameEn: "Algiers", country: "الجزائر", countryEn: "Algeria", latitude: 36.7538, longitude: 3.0588, timezone: "Africa/Algiers" },
  { id: "rabat", name: "الرباط", nameEn: "Rabat", country: "المغرب", countryEn: "Morocco", latitude: 34.0209, longitude: -6.8416, timezone: "Africa/Casablanca" },
  { id: "nouakchott", name: "نواكشوط", nameEn: "Nouakchott", country: "موريتانيا", countryEn: "Mauritania", latitude: 18.0735, longitude: -15.9582, timezone: "Africa/Nouakchott" },
  { id: "mogadishu", name: "مقديشو", nameEn: "Mogadishu", country: "الصومال", countryEn: "Somalia", latitude: 2.0469, longitude: 45.3182, timezone: "Africa/Mogadishu" },
  { id: "istanbul", name: "إستانبول", nameEn: "Istanbul", country: "تركيا", countryEn: "Turkey", latitude: 41.0082, longitude: 28.9784, timezone: "Europe/Istanbul" },
  { id: "london", name: "لندن", nameEn: "London", country: "المملكة المتحدة", countryEn: "United Kingdom", latitude: 51.5074, longitude: -0.1278, timezone: "Europe/London" },
  { id: "paris", name: "باريس", nameEn: "Paris", country: "فرنسا", countryEn: "France", latitude: 48.8566, longitude: 2.3522, timezone: "Europe/Paris" },
  { id: "berlin", name: "برلين", nameEn: "Berlin", country: "ألمانيا", countryEn: "Germany", latitude: 52.52, longitude: 13.405, timezone: "Europe/Berlin" },
  { id: "newyork", name: "نيويورك", nameEn: "New York", country: "الولايات المتحدة", countryEn: "United States", latitude: 40.7128, longitude: -74.0059, timezone: "America/New_York" },
  { id: "toronto", name: "تورونتو", nameEn: "Toronto", country: "كندا", countryEn: "Canada", latitude: 43.6532, longitude: -79.3832, timezone: "America/Toronto" },
  { id: "kualalumpur", name: "كوالالمبور", nameEn: "Kuala Lumpur", country: "ماليزيا", countryEn: "Malaysia", latitude: 3.139, longitude: 101.6869, timezone: "Asia/Kuala_Lumpur" },
  { id: "jakarta", name: "جاكرتا", nameEn: "Jakarta", country: "إندونيسيا", countryEn: "Indonesia", latitude: -6.2088, longitude: 106.8456, timezone: "Asia/Jakarta" },
  { id: "sydney", name: "سيدني", nameEn: "Sydney", country: "أستراليا", countryEn: "Australia", latitude: -33.8688, longitude: 151.2093, timezone: "Australia/Sydney" },
  { id: "karachi", name: "كراتشي", nameEn: "Karachi", country: "باكستان", countryEn: "Pakistan", latitude: 24.8607, longitude: 67.0011, timezone: "Asia/Karachi" },
  { id: "lahore", name: "لاهور", nameEn: "Lahore", country: "باكستان", countryEn: "Pakistan", latitude: 31.5204, longitude: 74.3587, timezone: "Asia/Karachi" },
  { id: "islamabad", name: "إسلام آباد", nameEn: "Islamabad", country: "باكستان", countryEn: "Pakistan", latitude: 33.6844, longitude: 73.0479, timezone: "Asia/Karachi" },
  { id: "delhi", name: "دلهي", nameEn: "Delhi", country: "الهند", countryEn: "India", latitude: 28.6139, longitude: 77.209, timezone: "Asia/Kolkata" },
  { id: "mumbai", name: "مومباي", nameEn: "Mumbai", country: "الهند", countryEn: "India", latitude: 19.076, longitude: 72.8777, timezone: "Asia/Kolkata" },
  { id: "hyderabad", name: "حيدر آباد", nameEn: "Hyderabad", country: "الهند", countryEn: "India", latitude: 17.385, longitude: 78.4867, timezone: "Asia/Kolkata" },
  { id: "dhaka", name: "دكا", nameEn: "Dhaka", country: "بنغلاديش", countryEn: "Bangladesh", latitude: 23.8103, longitude: 90.4125, timezone: "Asia/Dhaka" },
  { id: "colombo", name: "كولومبو", nameEn: "Colombo", country: "سريلانكا", countryEn: "Sri Lanka", latitude: 6.9271, longitude: 79.8612, timezone: "Asia/Colombo" },
  { id: "kabul", name: "كابول", nameEn: "Kabul", country: "أفغانستان", countryEn: "Afghanistan", latitude: 34.5553, longitude: 69.2075, timezone: "Asia/Kabul" },
  { id: "tehran", name: "طهران", nameEn: "Tehran", country: "إيران", countryEn: "Iran", latitude: 35.6892, longitude: 51.389, timezone: "Asia/Tehran" },
  { id: "tashkent", name: "طشقند", nameEn: "Tashkent", country: "أوزبكستان", countryEn: "Uzbekistan", latitude: 41.2995, longitude: 69.2401, timezone: "Asia/Tashkent" },
  { id: "baku", name: "باكو", nameEn: "Baku", country: "أذربيجان", countryEn: "Azerbaijan", latitude: 40.4093, longitude: 49.8671, timezone: "Asia/Baku" },
  { id: "sarajevo", name: "سراييفو", nameEn: "Sarajevo", country: "البوسنة", countryEn: "Bosnia", latitude: 43.8563, longitude: 18.4131, timezone: "Europe/Sarajevo" },
  { id: "moscow", name: "موسكو", nameEn: "Moscow", country: "روسيا", countryEn: "Russia", latitude: 55.7558, longitude: 37.6173, timezone: "Europe/Moscow" },
  { id: "singapore", name: "سنغافورة", nameEn: "Singapore", country: "سنغافورة", countryEn: "Singapore", latitude: 1.3521, longitude: 103.8198, timezone: "Asia/Singapore" },
  { id: "male", name: "ماليه", nameEn: "Malé", country: "المالديف", countryEn: "Maldives", latitude: 4.1755, longitude: 73.5093, timezone: "Indian/Maldives" },
  { id: "lagos", name: "لاغوس", nameEn: "Lagos", country: "نيجيريا", countryEn: "Nigeria", latitude: 6.5244, longitude: 3.3792, timezone: "Africa/Lagos" },
  { id: "abuja", name: "أبوجا", nameEn: "Abuja", country: "نيجيريا", countryEn: "Nigeria", latitude: 9.0765, longitude: 7.3986, timezone: "Africa/Lagos" },
  { id: "accra", name: "أكرا", nameEn: "Accra", country: "غانا", countryEn: "Ghana", latitude: 5.6037, longitude: -0.187, timezone: "Africa/Accra" },
  { id: "dakar", name: "داكار", nameEn: "Dakar", country: "السنغال", countryEn: "Senegal", latitude: 14.7167, longitude: -17.4677, timezone: "Africa/Dakar" },
  { id: "nairobi", name: "نيروبي", nameEn: "Nairobi", country: "كينيا", countryEn: "Kenya", latitude: -1.2921, longitude: 36.8219, timezone: "Africa/Nairobi" },
  { id: "djibouti", name: "جيبوتي", nameEn: "Djibouti", country: "جيبوتي", countryEn: "Djibouti", latitude: 11.5721, longitude: 43.1456, timezone: "Africa/Djibouti" },
  { id: "johannesburg", name: "جوهانسبرغ", nameEn: "Johannesburg", country: "جنوب أفريقيا", countryEn: "South Africa", latitude: -26.2041, longitude: 28.0473, timezone: "Africa/Johannesburg" },
  { id: "capetown", name: "كيب تاون", nameEn: "Cape Town", country: "جنوب أفريقيا", countryEn: "South Africa", latitude: -33.9249, longitude: 18.4241, timezone: "Africa/Johannesburg" },
];

/**
 * Every IANA zone the platform knows, plus the city presets and the saved zone.
 * Chromium/WebView2 exposes the full list; the city list is the fallback.
 */
export function timezoneChoices(current?: string): string[] {
  const zones = new Set<string>(cities.map((city) => city.timezone));
  const supported = (
    Intl as unknown as { supportedValuesOf?: (key: string) => string[] }
  ).supportedValuesOf?.("timeZone");
  for (const zone of supported ?? []) zones.add(zone);
  zones.add("UTC");
  if (current) zones.add(current);
  return [...zones].sort();
}

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
