// Development fixture — used only when the UI runs in a plain browser (`npm run dev`).
// The desktop app talks to the Rust providers instead. Arabic text here is a
// sample; only Al-Fatiha is real so the follow-along layout can be previewed.

import type {
  AdhkarDay,
  AdhkarProgress,
  AdhkarStreak,
  AppInfo,
  Ayah,
  AyahReciter,
  DownloadRow,
  HijriDate,
  HotkeyMap,
  ImportSummary,
  Juz,
  Memorization,
  Playlist,
  PrayerDay,
  PrayerLog,
  PrayerStreak,
  QiblaInfo,
  QuranBookmark,
  QuranPage,
  ReaderPosition,
  Reciter,
  SearchResults,
  Surah,
  Track,
  WorshipSettings,
} from "./types";

const SURAHS: Surah[] = [{"number":1,"name":"سُورَةُ ٱلْفَاتِحَةِ","englishName":"Al-Faatiha","meaning":"The Opening","ayahs":7,"revelation":"makkah"},{"number":2,"name":"سُورَةُ البَقَرَةِ","englishName":"Al-Baqara","meaning":"The Cow","ayahs":286,"revelation":"madinah"},{"number":3,"name":"سُورَةُ آلِ عِمۡرَانَ","englishName":"Aal-i-Imraan","meaning":"The Family of Imraan","ayahs":200,"revelation":"madinah"},{"number":4,"name":"سُورَةُ النِّسَاءِ","englishName":"An-Nisaa","meaning":"The Women","ayahs":176,"revelation":"madinah"},{"number":5,"name":"سُورَةُ المَائـِدَةِ","englishName":"Al-Maaida","meaning":"The Table","ayahs":120,"revelation":"madinah"},{"number":6,"name":"سُورَةُ الأَنۡعَامِ","englishName":"Al-An'aam","meaning":"The Cattle","ayahs":165,"revelation":"makkah"},{"number":7,"name":"سُورَةُ الأَعۡرَافِ","englishName":"Al-A'raaf","meaning":"The Heights","ayahs":206,"revelation":"makkah"},{"number":8,"name":"سُورَةُ الأَنفَالِ","englishName":"Al-Anfaal","meaning":"The Spoils of War","ayahs":75,"revelation":"madinah"},{"number":9,"name":"سُورَةُ التَّوۡبَةِ","englishName":"At-Tawba","meaning":"The Repentance","ayahs":129,"revelation":"madinah"},{"number":10,"name":"سُورَةُ يُونُسَ","englishName":"Yunus","meaning":"Jonas","ayahs":109,"revelation":"makkah"},{"number":11,"name":"سُورَةُ هُودٍ","englishName":"Hud","meaning":"Hud","ayahs":123,"revelation":"makkah"},{"number":12,"name":"سُورَةُ يُوسُفَ","englishName":"Yusuf","meaning":"Joseph","ayahs":111,"revelation":"makkah"},{"number":13,"name":"سُورَةُ الرَّعۡدِ","englishName":"Ar-Ra'd","meaning":"The Thunder","ayahs":43,"revelation":"madinah"},{"number":14,"name":"سُورَةُ إِبۡرَاهِيمَ","englishName":"Ibrahim","meaning":"Abraham","ayahs":52,"revelation":"makkah"},{"number":15,"name":"سُورَةُ الحِجۡرِ","englishName":"Al-Hijr","meaning":"The Rock","ayahs":99,"revelation":"makkah"},{"number":16,"name":"سُورَةُ النَّحۡلِ","englishName":"An-Nahl","meaning":"The Bee","ayahs":128,"revelation":"makkah"},{"number":17,"name":"سُورَةُ الإِسۡرَاءِ","englishName":"Al-Israa","meaning":"The Night Journey","ayahs":111,"revelation":"makkah"},{"number":18,"name":"سُورَةُ الكَهۡفِ","englishName":"Al-Kahf","meaning":"The Cave","ayahs":110,"revelation":"makkah"},{"number":19,"name":"سُورَةُ مَرۡيَمَ","englishName":"Maryam","meaning":"Mary","ayahs":98,"revelation":"makkah"},{"number":20,"name":"سُورَةُ طه","englishName":"Taa-Haa","meaning":"Taa-Haa","ayahs":135,"revelation":"makkah"},{"number":21,"name":"سُورَةُ الأَنبِيَاءِ","englishName":"Al-Anbiyaa","meaning":"The Prophets","ayahs":112,"revelation":"makkah"},{"number":22,"name":"سُورَةُ الحَجِّ","englishName":"Al-Hajj","meaning":"The Pilgrimage","ayahs":78,"revelation":"madinah"},{"number":23,"name":"سُورَةُ المُؤۡمِنُونَ","englishName":"Al-Muminoon","meaning":"The Believers","ayahs":118,"revelation":"makkah"},{"number":24,"name":"سُورَةُ النُّورِ","englishName":"An-Noor","meaning":"The Light","ayahs":64,"revelation":"madinah"},{"number":25,"name":"سُورَةُ الفُرۡقَانِ","englishName":"Al-Furqaan","meaning":"The Criterion","ayahs":77,"revelation":"makkah"},{"number":26,"name":"سُورَةُ الشُّعَرَاءِ","englishName":"Ash-Shu'araa","meaning":"The Poets","ayahs":227,"revelation":"makkah"},{"number":27,"name":"سُورَةُ النَّمۡلِ","englishName":"An-Naml","meaning":"The Ant","ayahs":93,"revelation":"makkah"},{"number":28,"name":"سُورَةُ القَصَصِ","englishName":"Al-Qasas","meaning":"The Stories","ayahs":88,"revelation":"makkah"},{"number":29,"name":"سُورَةُ العَنكَبُوتِ","englishName":"Al-Ankaboot","meaning":"The Spider","ayahs":69,"revelation":"makkah"},{"number":30,"name":"سُورَةُ الرُّومِ","englishName":"Ar-Room","meaning":"The Romans","ayahs":60,"revelation":"makkah"},{"number":31,"name":"سُورَةُ لُقۡمَانَ","englishName":"Luqman","meaning":"Luqman","ayahs":34,"revelation":"makkah"},{"number":32,"name":"سُورَةُ السَّجۡدَةِ","englishName":"As-Sajda","meaning":"The Prostration","ayahs":30,"revelation":"makkah"},{"number":33,"name":"سُورَةُ الأَحۡزَابِ","englishName":"Al-Ahzaab","meaning":"The Clans","ayahs":73,"revelation":"madinah"},{"number":34,"name":"سُورَةُ سَبَإٍ","englishName":"Saba","meaning":"Sheba","ayahs":54,"revelation":"makkah"},{"number":35,"name":"سُورَةُ فَاطِرٍ","englishName":"Faatir","meaning":"The Originator","ayahs":45,"revelation":"makkah"},{"number":36,"name":"سُورَةُ يسٓ","englishName":"Yaseen","meaning":"Yaseen","ayahs":83,"revelation":"makkah"},{"number":37,"name":"سُورَةُ الصَّافَّاتِ","englishName":"As-Saaffaat","meaning":"Those drawn up in Ranks","ayahs":182,"revelation":"makkah"},{"number":38,"name":"سُورَةُ صٓ","englishName":"Saad","meaning":"The letter Saad","ayahs":88,"revelation":"makkah"},{"number":39,"name":"سُورَةُ الزُّمَرِ","englishName":"Az-Zumar","meaning":"The Groups","ayahs":75,"revelation":"makkah"},{"number":40,"name":"سُورَةُ غَافِرٍ","englishName":"Ghafir","meaning":"The Forgiver","ayahs":85,"revelation":"makkah"},{"number":41,"name":"سُورَةُ فُصِّلَتۡ","englishName":"Fussilat","meaning":"Explained in detail","ayahs":54,"revelation":"makkah"},{"number":42,"name":"سُورَةُ الشُّورَىٰ","englishName":"Ash-Shura","meaning":"Consultation","ayahs":53,"revelation":"makkah"},{"number":43,"name":"سُورَةُ الزُّخۡرُفِ","englishName":"Az-Zukhruf","meaning":"Ornaments of gold","ayahs":89,"revelation":"makkah"},{"number":44,"name":"سُورَةُ الدُّخَانِ","englishName":"Ad-Dukhaan","meaning":"The Smoke","ayahs":59,"revelation":"makkah"},{"number":45,"name":"سُورَةُ الجَاثِيَةِ","englishName":"Al-Jaathiya","meaning":"Crouching","ayahs":37,"revelation":"makkah"},{"number":46,"name":"سُورَةُ الأَحۡقَافِ","englishName":"Al-Ahqaf","meaning":"The Dunes","ayahs":35,"revelation":"makkah"},{"number":47,"name":"سُورَةُ مُحَمَّدٍ","englishName":"Muhammad","meaning":"Muhammad","ayahs":38,"revelation":"madinah"},{"number":48,"name":"سُورَةُ الفَتۡحِ","englishName":"Al-Fath","meaning":"The Victory","ayahs":29,"revelation":"madinah"},{"number":49,"name":"سُورَةُ الحُجُرَاتِ","englishName":"Al-Hujuraat","meaning":"The Inner Apartments","ayahs":18,"revelation":"madinah"},{"number":50,"name":"سُورَةُ قٓ","englishName":"Qaaf","meaning":"The letter Qaaf","ayahs":45,"revelation":"makkah"},{"number":51,"name":"سُورَةُ الذَّارِيَاتِ","englishName":"Adh-Dhaariyat","meaning":"The Winnowing Winds","ayahs":60,"revelation":"makkah"},{"number":52,"name":"سُورَةُ الطُّورِ","englishName":"At-Tur","meaning":"The Mount","ayahs":49,"revelation":"makkah"},{"number":53,"name":"سُورَةُ النَّجۡمِ","englishName":"An-Najm","meaning":"The Star","ayahs":62,"revelation":"makkah"},{"number":54,"name":"سُورَةُ القَمَرِ","englishName":"Al-Qamar","meaning":"The Moon","ayahs":55,"revelation":"makkah"},{"number":55,"name":"سُورَةُ الرَّحۡمَٰن","englishName":"Ar-Rahmaan","meaning":"The Beneficent","ayahs":78,"revelation":"madinah"},{"number":56,"name":"سُورَةُ الوَاقِعَةِ","englishName":"Al-Waaqia","meaning":"The Inevitable","ayahs":96,"revelation":"makkah"},{"number":57,"name":"سُورَةُ الحَدِيدِ","englishName":"Al-Hadid","meaning":"The Iron","ayahs":29,"revelation":"madinah"},{"number":58,"name":"سُورَةُ المُجَادلَةِ","englishName":"Al-Mujaadila","meaning":"The Pleading Woman","ayahs":22,"revelation":"madinah"},{"number":59,"name":"سُورَةُ الحَشۡرِ","englishName":"Al-Hashr","meaning":"The Exile","ayahs":24,"revelation":"madinah"},{"number":60,"name":"سُورَةُ المُمۡتَحنَةِ","englishName":"Al-Mumtahana","meaning":"She that is to be examined","ayahs":13,"revelation":"madinah"},{"number":61,"name":"سُورَةُ الصَّفِّ","englishName":"As-Saff","meaning":"The Ranks","ayahs":14,"revelation":"madinah"},{"number":62,"name":"سُورَةُ الجُمُعَةِ","englishName":"Al-Jumu'a","meaning":"Friday","ayahs":11,"revelation":"madinah"},{"number":63,"name":"سُورَةُ المُنَافِقُونَ","englishName":"Al-Munaafiqoon","meaning":"The Hypocrites","ayahs":11,"revelation":"madinah"},{"number":64,"name":"سُورَةُ التَّغَابُنِ","englishName":"At-Taghaabun","meaning":"Mutual Disillusion","ayahs":18,"revelation":"madinah"},{"number":65,"name":"سُورَةُ الطَّلَاقِ","englishName":"At-Talaaq","meaning":"Divorce","ayahs":12,"revelation":"madinah"},{"number":66,"name":"سُورَةُ التَّحۡرِيمِ","englishName":"At-Tahrim","meaning":"The Prohibition","ayahs":12,"revelation":"madinah"},{"number":67,"name":"سُورَةُ المُلۡكِ","englishName":"Al-Mulk","meaning":"The Sovereignty","ayahs":30,"revelation":"makkah"},{"number":68,"name":"سُورَةُ القَلَمِ","englishName":"Al-Qalam","meaning":"The Pen","ayahs":52,"revelation":"makkah"},{"number":69,"name":"سُورَةُ الحَاقَّةِ","englishName":"Al-Haaqqa","meaning":"The Reality","ayahs":52,"revelation":"makkah"},{"number":70,"name":"سُورَةُ المَعَارِجِ","englishName":"Al-Ma'aarij","meaning":"The Ascending Stairways","ayahs":44,"revelation":"makkah"},{"number":71,"name":"سُورَةُ نُوحٍ","englishName":"Nooh","meaning":"Noah","ayahs":28,"revelation":"makkah"},{"number":72,"name":"سُورَةُ الجِنِّ","englishName":"Al-Jinn","meaning":"The Jinn","ayahs":28,"revelation":"makkah"},{"number":73,"name":"سُورَةُ المُزَّمِّلِ","englishName":"Al-Muzzammil","meaning":"The Enshrouded One","ayahs":20,"revelation":"makkah"},{"number":74,"name":"سُورَةُ المُدَّثِّرِ","englishName":"Al-Muddaththir","meaning":"The Cloaked One","ayahs":56,"revelation":"makkah"},{"number":75,"name":"سُورَةُ القِيَامَةِ","englishName":"Al-Qiyaama","meaning":"The Resurrection","ayahs":40,"revelation":"makkah"},{"number":76,"name":"سُورَةُ الإِنسَانِ","englishName":"Al-Insaan","meaning":"Man","ayahs":31,"revelation":"madinah"},{"number":77,"name":"سُورَةُ المُرۡسَلَاتِ","englishName":"Al-Mursalaat","meaning":"The Emissaries","ayahs":50,"revelation":"makkah"},{"number":78,"name":"سُورَةُ النَّبَإِ","englishName":"An-Naba","meaning":"The Announcement","ayahs":40,"revelation":"makkah"},{"number":79,"name":"سُورَةُ النَّازِعَاتِ","englishName":"An-Naazi'aat","meaning":"Those who drag forth","ayahs":46,"revelation":"makkah"},{"number":80,"name":"سُورَةُ عَبَسَ","englishName":"Abasa","meaning":"He frowned","ayahs":42,"revelation":"makkah"},{"number":81,"name":"سُورَةُ التَّكۡوِيرِ","englishName":"At-Takwir","meaning":"The Overthrowing","ayahs":29,"revelation":"makkah"},{"number":82,"name":"سُورَةُ الانفِطَارِ","englishName":"Al-Infitaar","meaning":"The Cleaving","ayahs":19,"revelation":"makkah"},{"number":83,"name":"سُورَةُ المُطَفِّفِينَ","englishName":"Al-Mutaffifin","meaning":"Defrauding","ayahs":36,"revelation":"makkah"},{"number":84,"name":"سُورَةُ الانشِقَاقِ","englishName":"Al-Inshiqaaq","meaning":"The Splitting Open","ayahs":25,"revelation":"makkah"},{"number":85,"name":"سُورَةُ البُرُوجِ","englishName":"Al-Burooj","meaning":"The Constellations","ayahs":22,"revelation":"makkah"},{"number":86,"name":"سُورَةُ الطَّارِقِ","englishName":"At-Taariq","meaning":"The Morning Star","ayahs":17,"revelation":"makkah"},{"number":87,"name":"سُورَةُ الأَعۡلَىٰ","englishName":"Al-A'laa","meaning":"The Most High","ayahs":19,"revelation":"makkah"},{"number":88,"name":"سُورَةُ الغَاشِيَةِ","englishName":"Al-Ghaashiya","meaning":"The Overwhelming","ayahs":26,"revelation":"makkah"},{"number":89,"name":"سُورَةُ الفَجۡرِ","englishName":"Al-Fajr","meaning":"The Dawn","ayahs":30,"revelation":"makkah"},{"number":90,"name":"سُورَةُ البَلَدِ","englishName":"Al-Balad","meaning":"The City","ayahs":20,"revelation":"makkah"},{"number":91,"name":"سُورَةُ الشَّمۡسِ","englishName":"Ash-Shams","meaning":"The Sun","ayahs":15,"revelation":"makkah"},{"number":92,"name":"سُورَةُ اللَّيۡلِ","englishName":"Al-Lail","meaning":"The Night","ayahs":21,"revelation":"makkah"},{"number":93,"name":"سُورَةُ الضُّحَىٰ","englishName":"Ad-Dhuhaa","meaning":"The Morning Hours","ayahs":11,"revelation":"makkah"},{"number":94,"name":"سُورَةُ الشَّرۡحِ","englishName":"Ash-Sharh","meaning":"The Consolation","ayahs":8,"revelation":"makkah"},{"number":95,"name":"سُورَةُ التِّينِ","englishName":"At-Tin","meaning":"The Fig","ayahs":8,"revelation":"makkah"},{"number":96,"name":"سُورَةُ العَلَقِ","englishName":"Al-Alaq","meaning":"The Clot","ayahs":19,"revelation":"makkah"},{"number":97,"name":"سُورَةُ القَدۡرِ","englishName":"Al-Qadr","meaning":"The Power, Fate","ayahs":5,"revelation":"makkah"},{"number":98,"name":"سُورَةُ البَيِّنَةِ","englishName":"Al-Bayyina","meaning":"The Evidence","ayahs":8,"revelation":"madinah"},{"number":99,"name":"سُورَةُ الزَّلۡزَلَةِ","englishName":"Az-Zalzala","meaning":"The Earthquake","ayahs":8,"revelation":"madinah"},{"number":100,"name":"سُورَةُ العَادِيَاتِ","englishName":"Al-Aadiyaat","meaning":"The Chargers","ayahs":11,"revelation":"makkah"},{"number":101,"name":"سُورَةُ القَارِعَةِ","englishName":"Al-Qaari'a","meaning":"The Calamity","ayahs":11,"revelation":"makkah"},{"number":102,"name":"سُورَةُ التَّكَاثُرِ","englishName":"At-Takaathur","meaning":"Competition","ayahs":8,"revelation":"makkah"},{"number":103,"name":"سُورَةُ العَصۡرِ","englishName":"Al-Asr","meaning":"The Declining Day, Epoch","ayahs":3,"revelation":"makkah"},{"number":104,"name":"سُورَةُ الهُمَزَةِ","englishName":"Al-Humaza","meaning":"The Traducer","ayahs":9,"revelation":"makkah"},{"number":105,"name":"سُورَةُ الفِيلِ","englishName":"Al-Fil","meaning":"The Elephant","ayahs":5,"revelation":"makkah"},{"number":106,"name":"سُورَةُ قُرَيۡشٍ","englishName":"Quraish","meaning":"Quraysh","ayahs":4,"revelation":"makkah"},{"number":107,"name":"سُورَةُ المَاعُونِ","englishName":"Al-Maa'un","meaning":"Almsgiving","ayahs":7,"revelation":"makkah"},{"number":108,"name":"سُورَةُ الكَوۡثَرِ","englishName":"Al-Kawthar","meaning":"Abundance","ayahs":3,"revelation":"makkah"},{"number":109,"name":"سُورَةُ الكَافِرُونَ","englishName":"Al-Kaafiroon","meaning":"The Disbelievers","ayahs":6,"revelation":"makkah"},{"number":110,"name":"سُورَةُ النَّصۡرِ","englishName":"An-Nasr","meaning":"Divine Support","ayahs":3,"revelation":"madinah"},{"number":111,"name":"سُورَةُ المَسَدِ","englishName":"Al-Masad","meaning":"The Palm Fibre","ayahs":5,"revelation":"makkah"},{"number":112,"name":"سُورَةُ الإِخۡلَاصِ","englishName":"Al-Ikhlaas","meaning":"Sincerity","ayahs":4,"revelation":"makkah"},{"number":113,"name":"سُورَةُ الفَلَقِ","englishName":"Al-Falaq","meaning":"The Dawn","ayahs":5,"revelation":"makkah"},{"number":114,"name":"سُورَةُ النَّاسِ","englishName":"An-Naas","meaning":"Mankind","ayahs":6,"revelation":"makkah"}];

const RECITERS: Reciter[] = [
  {
    "id": 118,
    "name": "محمود خليل الحصري",
    "letter": "م",
    "moshafs": [
      {
        "id": 270,
        "name": "قالون عن نافع - مرتل",
        "server": "https://cdn.mp3quran.net/audio/mahmoud-husary/r5/",
        "surahTotal": 114,
        "surahs": [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      },
      {
        "id": 269,
        "name": "الدوري عن أبي عمرو - مرتل",
        "server": "https://cdn.mp3quran.net/audio/mahmoud-husary/r4/",
        "surahTotal": 114,
        "surahs": [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      }
    ]
  },
  {
    "id": 112,
    "name": "محمد صديق المنشاوي",
    "letter": "م",
    "moshafs": [
      {
        "id": 10924,
        "name": "حفص عن عاصم - تسجيل عام 1387 هـ - 1967م",
        "server": "https://cdn.mp3quran.net/audio/muhammad-minshawi/r4/",
        "surahTotal": 110,
        "surahs": [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          17,
          18,
          19,
          20,
          21,
          22,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      },
      {
        "id": 114,
        "name": "حفص عن عاصم - المصحف المعلم",
        "server": "https://cdn.mp3quran.net/audio/muhammad-minshawi/r3/",
        "surahTotal": 114,
        "surahs": [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      }
    ]
  },
  {
    "id": 123,
    "name": "مشاري العفاسي",
    "letter": "م",
    "moshafs": [
      {
        "id": 124,
        "name": "الدوري عن الكسائي - مرتل",
        "server": "https://cdn.mp3quran.net/audio/mishary-alafasy/r2/",
        "surahTotal": 6,
        "surahs": [
          12,
          14,
          25,
          87,
          97,
          99
        ]
      },
      {
        "id": 123,
        "name": "حفص عن عاصم - مرتل",
        "server": "https://cdn.mp3quran.net/audio/mishary-alafasy/r1/",
        "surahTotal": 114,
        "surahs": [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      }
    ]
  },
  {
    "id": 54,
    "name": "عبدالرحمن السديس",
    "letter": "ع",
    "moshafs": [
      {
        "id": 54,
        "name": "حفص عن عاصم - مرتل",
        "server": "https://cdn.mp3quran.net/audio/abdulrahman-sudais/r1/",
        "surahTotal": 114,
        "surahs": [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      }
    ]
  },
  {
    "id": 218,
    "name": "خالد الشريمي",
    "letter": "خ",
    "moshafs": [
      {
        "id": 218,
        "name": "حفص عن عاصم - مرتل",
        "server": "https://cdn.mp3quran.net/audio/khalid-shuraimi/r1/",
        "surahTotal": 73,
        "surahs": [
          1,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      }
    ]
  },
  {
    "id": 1,
    "name": "إبراهيم الأخضر",
    "letter": "إ",
    "moshafs": [
      {
        "id": 1,
        "name": "حفص عن عاصم - مرتل",
        "server": "https://cdn.mp3quran.net/audio/ibrahim-akhdar/r1/",
        "surahTotal": 114,
        "surahs": [
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
          20,
          21,
          22,
          23,
          24,
          25,
          26,
          27,
          28,
          29,
          30,
          31,
          32,
          33,
          34,
          35,
          36,
          37,
          38,
          39,
          40,
          41,
          42,
          43,
          44,
          45,
          46,
          47,
          48,
          49,
          50,
          51,
          52,
          53,
          54,
          55,
          56,
          57,
          58,
          59,
          60,
          61,
          62,
          63,
          64,
          65,
          66,
          67,
          68,
          69,
          70,
          71,
          72,
          73,
          74,
          75,
          76,
          77,
          78,
          79,
          80,
          81,
          82,
          83,
          84,
          85,
          86,
          87,
          88,
          89,
          90,
          91,
          92,
          93,
          94,
          95,
          96,
          97,
          98,
          99,
          100,
          101,
          102,
          103,
          104,
          105,
          106,
          107,
          108,
          109,
          110,
          111,
          112,
          113,
          114
        ]
      }
    ]
  }
];

const STATIONS: Track[] = [
  {
    "id": "radiobrowser:807f5b26-6035-4803-812e-3199fc97b7e9",
    "provider": "radiobrowser",
    "providerId": "807f5b26-6035-4803-812e-3199fc97b7e9",
    "title": "Saudi Quran1",
    "artist": "Saudi Arabia",
    "streamUrl": "http://n01.radiojar.com/0tpy1h0kxtzuv?rj-ttl=5&rj-tok=AAABjrUiYUAAxwNU2wDdcOap9w",
    "artworkUrl": "https://aloula.faulio.com/storage/mediagallery/c9/19/small_144a972e52acb9b4a3a3151fb0b7aa84509d14b5.png",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3"
  },
  {
    "id": "radiobrowser:075e5897-3bb9-4eaf-a418-ebdd7cba957e",
    "provider": "radiobrowser",
    "providerId": "075e5897-3bb9-4eaf-a418-ebdd7cba957e",
    "title": "Al Arabiya FM",
    "artist": "Saudi Arabia",
    "album": "news",
    "streamUrl": "https://fm.alarabiya.net/fm/myStream/playlist.m3u8",
    "kind": "radio",
    "live": true,
    "subtitle": "AAC · 128 kbps"
  },
  {
    "id": "radiobrowser:a481fed1-b46b-44da-9f9b-cc5c4820189b",
    "provider": "radiobrowser",
    "providerId": "a481fed1-b46b-44da-9f9b-cc5c4820189b",
    "title": "إذاعة الأخبار كل 5 دقائق   REPLAY NEWS - العربية",
    "artist": "Saudi Arabia",
    "album": "news",
    "streamUrl": "https://replaynewsar.ice.infomaniak.ch/replaynewsar-128.mp3",
    "artworkUrl": "https://www.publicsante.com/BIENVENU/LOGO%20REPLAY%20NEWS-AR.png",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 128 kbps"
  },
  {
    "id": "radiobrowser:8a753c11-ee4a-42bf-8e4d-6d852cac9030",
    "provider": "radiobrowser",
    "providerId": "8a753c11-ee4a-42bf-8e4d-6d852cac9030",
    "title": "القارئ علي الحذيفي رواية قالون",
    "artist": "Saudi Arabia",
    "album": "classical",
    "streamUrl": "https://qurango.net/radio/ali_alhuthaifi_qalon",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 128 kbps"
  },
  {
    "id": "radiobrowser:0bd2d571-7fc8-4158-8e8e-0635c9a330ad",
    "provider": "radiobrowser",
    "providerId": "0bd2d571-7fc8-4158-8e8e-0635c9a330ad",
    "title": "MBC FM",
    "artist": "Saudi Arabia",
    "streamUrl": "https://radio-mbcfm.mbc.net/radio-mbcfm_1.m3u8",
    "artworkUrl": "https://assets-new.mbcmood.com/mbc-mood/channel/6adb0cd12bdd7.png",
    "kind": "radio",
    "live": true,
    "subtitle": "UNKNOWN"
  },
  {
    "id": "radiobrowser:fc985cbf-dc77-4f7a-b353-d981c1344c9b",
    "provider": "radiobrowser",
    "providerId": "fc985cbf-dc77-4f7a-b353-d981c1344c9b",
    "title": "Rotana FM",
    "artist": "Saudi Arabia",
    "album": "arabic,riyadh",
    "streamUrl": "http://philae.shoutca.st:8250/stream",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 128 kbps"
  },
  {
    "id": "radiobrowser:ce30edd2-f94a-4e37-8409-c8df9dd1330a",
    "provider": "radiobrowser",
    "providerId": "ce30edd2-f94a-4e37-8409-c8df9dd1330a",
    "title": "إذاعة القرآن الكريم (مكة المكرمة)",
    "artist": "Saudi Arabia",
    "streamUrl": "https://n05.radiojar.com/4wqre23fytzuv?rj-ttl=5&rj-tok=AAABlo7vOaoAkavc0CM0frQ6zQ",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3"
  },
  {
    "id": "radiobrowser:f483fc26-d6c7-4d16-8b81-03e4e8683643",
    "provider": "radiobrowser",
    "providerId": "f483fc26-d6c7-4d16-8b81-03e4e8683643",
    "title": "AlifAlif FM",
    "artist": "Saudi Arabia",
    "streamUrl": "https://alifalifjobs.com/radio/8000/AlifAlifLive.mp3",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 128 kbps"
  },
  {
    "id": "radiobrowser:e2d75665-c4a9-4433-b953-3a5346ae5fb6",
    "provider": "radiobrowser",
    "providerId": "e2d75665-c4a9-4433-b953-3a5346ae5fb6",
    "title": "Fred Film Radio(لغة عربية)",
    "artist": "Saudi Arabia",
    "album": "culture,film,movie",
    "streamUrl": "https://s10.webradio-hosting.com/proxy/fredradioar/stream",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 128 kbps"
  },
  {
    "id": "radiobrowser:7fcb9e0d-803e-4c4a-8c50-a7679084546d",
    "provider": "radiobrowser",
    "providerId": "7fcb9e0d-803e-4c4a-8c50-a7679084546d",
    "title": "SBA Riyadh Radio 91.5 FM",
    "artist": "Saudi Arabia",
    "album": "variety,world middle east",
    "streamUrl": "https://stream-154.zeno.fm/pdeizhgrtrstv?zt=eyJhbGciOiJIUzI1NiJ9.eyJzdHJlYW0iOiJwZGVpemhncnRyc3R2IiwiaG9zdCI6InN0cmVhbS0xNTQuemVuby5mbSIsInJ0dGwiOjUsImp0aSI6Im9vbng2V1J3UXJ5Q0k5TVV0N01heEEiLCJpYXQiOjE3MjgyMjQ1MTYsImV4cCI6MTcyODIyNDU3Nn0.gpUIWkDBFNNFjqCg2R-xQN4LXT4z8_Ivs7d2UkeFE_8",
    "artworkUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSRgMTJM5UUoqtPGDPy6_wwfqjCpLw6yQxVDg&s",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 128 kbps"
  },
  {
    "id": "radiobrowser:6a329c2f-af42-4224-83b4-13358dbe5db5",
    "provider": "radiobrowser",
    "providerId": "6a329c2f-af42-4224-83b4-13358dbe5db5",
    "title": "Maura ✨ ( AR )",
    "artist": "Saudi Arabia",
    "album": "arab music,egyptian songs,اغاني كلاسيكيه",
    "streamUrl": "https://stream.zeno.fm/fpasc3up26ptv",
    "artworkUrl": "https://stream.zeno.fm/fpasc3up26ptv.pls",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 128 kbps"
  },
  {
    "id": "radiobrowser:3da33a8b-06b7-4fd7-8001-121cee38e651",
    "provider": "radiobrowser",
    "providerId": "3da33a8b-06b7-4fd7-8001-121cee38e651",
    "title": "HOUB Radio (حُب)",
    "artist": "Saudi Arabia",
    "album": "music,الموسيقى العربية,كلاسيك",
    "streamUrl": "http://nap.casthost.net:8028/stream",
    "artworkUrl": "https://houb.com/img/logo/houb.png",
    "kind": "radio",
    "live": true,
    "subtitle": "MP3 · 64 kbps"
  }
];

const pad = (n: number) => String(n).padStart(3, "0");

const FATIHA = [
  "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
  "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
  "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
  "مَٰلِكِ يَوْمِ ٱلدِّينِ",
  "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
  "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ",
  "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ",
];

const AYAH_RECITERS: AyahReciter[] = [
  { id: "Husary_Muallim_128kbps", name: "محمود خليل الحصري (المعلّم)", english: "Al-Husary (teaching)", style: "معلم", bitrate: 128 },
  { id: "Husary_128kbps", name: "محمود خليل الحصري", english: "Mahmoud Al-Husary", style: "مرتل", bitrate: 128 },
  { id: "Minshawy_Teacher_128kbps", name: "محمد صديق المنشاوي (المعلّم)", english: "Al-Minshawi (teaching)", style: "معلم", bitrate: 128 },
  { id: "Minshawy_Murattal_128kbps", name: "محمد صديق المنشاوي", english: "Al-Minshawi", style: "مرتل", bitrate: 128 },
  { id: "Alafasy_128kbps", name: "مشاري العفاسي", english: "Mishary Alafasy", style: "مرتل", bitrate: 128 },
  { id: "Abdul_Basit_Murattal_192kbps", name: "عبد الباسط عبد الصمد", english: "Abdul Basit", style: "مرتل", bitrate: 192 },
  { id: "Abdurrahmaan_As-Sudais_192kbps", name: "عبد الرحمن السديس", english: "Abdurrahman As-Sudais", style: "مرتل", bitrate: 192 },
  { id: "Ghamadi_40kbps", name: "سعد الغامدي", english: "Saad Al-Ghamdi", style: "مرتل", bitrate: 40 },
];

/** Browser-mode hifz progress lives in memory; the desktop app uses SQLite. */
const memorized = new Map<number, number[]>();
const positions = new Map<string, number>();

/** Browser-mode library data. Downloads and local import need the desktop app. */
const favoriteSet = new Map<string, Track>();
const playlistStore = new Map<string, { meta: Playlist; tracks: Track[] }>();
const downloadsStore = new Map<string, DownloadRow>();
const prayerLogStore = new Map<string, PrayerLog>();
const adhkarProgressStore = new Map<string, Map<string, number>>();
const adhkarDayStore = new Map<string, AdhkarDay>();
const quranBookmarkStore = new Map<string, QuranBookmark>();
let readerPositionStore: ReaderPosition | null = null;

const JUZS: Juz[] = [
  { number: 1, surah: 1, ayah: 1, ayahs: 148 },
  { number: 2, surah: 2, ayah: 142, ayahs: 111 },
  { number: 3, surah: 2, ayah: 253, ayahs: 126 },
  { number: 4, surah: 3, ayah: 93, ayahs: 131 },
  { number: 5, surah: 4, ayah: 24, ayahs: 124 },
  { number: 6, surah: 4, ayah: 148, ayahs: 110 },
  { number: 7, surah: 5, ayah: 82, ayahs: 149 },
  { number: 8, surah: 6, ayah: 111, ayahs: 142 },
  { number: 9, surah: 7, ayah: 88, ayahs: 159 },
  { number: 10, surah: 8, ayah: 41, ayahs: 127 },
  { number: 11, surah: 9, ayah: 93, ayahs: 151 },
  { number: 12, surah: 11, ayah: 6, ayahs: 170 },
  { number: 13, surah: 12, ayah: 53, ayahs: 154 },
  { number: 14, surah: 15, ayah: 1, ayahs: 227 },
  { number: 15, surah: 17, ayah: 1, ayahs: 185 },
  { number: 16, surah: 18, ayah: 75, ayahs: 269 },
  { number: 17, surah: 21, ayah: 1, ayahs: 190 },
  { number: 18, surah: 23, ayah: 1, ayahs: 202 },
  { number: 19, surah: 25, ayah: 21, ayahs: 339 },
  { number: 20, surah: 27, ayah: 56, ayahs: 171 },
  { number: 21, surah: 29, ayah: 46, ayahs: 178 },
  { number: 22, surah: 33, ayah: 31, ayahs: 169 },
  { number: 23, surah: 36, ayah: 28, ayahs: 357 },
  { number: 24, surah: 39, ayah: 32, ayahs: 175 },
  { number: 25, surah: 41, ayah: 47, ayahs: 246 },
  { number: 26, surah: 46, ayah: 1, ayahs: 195 },
  { number: 27, surah: 51, ayah: 31, ayahs: 399 },
  { number: 28, surah: 58, ayah: 1, ayahs: 137 },
  { number: 29, surah: 67, ayah: 1, ayahs: 431 },
  { number: 30, surah: 78, ayah: 1, ayahs: 564 },
];

function todayKey(): string {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: MOCK_WORSHIP.timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());
  const value = (type: string) => parts.find((part) => part.type === type)?.value ?? "";
  return `${value("year")}-${value("month")}-${value("day")}`;
}

function mockAdhkarDay(date: string): AdhkarDay {
  return adhkarDayStore.get(date) ?? { date, morning: false, evening: false };
}

function mockAdhkarProgress(date: string): AdhkarProgress[] {
  const map = adhkarProgressStore.get(date);
  if (!map) return [];
  return [...map.entries()]
    .map(([key, remaining]) => {
      const [categoryId, itemId] = key.split("::");
      return { date, categoryId, itemId, remaining };
    })
    .sort((a, b) =>
      `${a.categoryId}::${a.itemId}`.localeCompare(`${b.categoryId}::${b.itemId}`),
    );
}

function mockAdhkarStreak(): AdhkarStreak {
  const days = [...adhkarDayStore.values()].sort((a, b) => a.date.localeCompare(b.date));
  const qualifies = (day?: AdhkarDay) => !!day && (day.morning || day.evening);
  const today = todayKey();
  let current = 0;
  const cursor = new Date(today + "T00:00:00Z");
  if (Number.isNaN(cursor.getTime())) {
    return { current: 0, best: 0, todayMorning: false, todayEvening: false };
  }
  if (!qualifies(adhkarDayStore.get(today))) cursor.setUTCDate(cursor.getUTCDate() - 1);
  while (qualifies(adhkarDayStore.get(cursor.toISOString().slice(0, 10)))) {
    current += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }

  let best = 0;
  let run = 0;
  let previous = "";
  for (const day of days) {
    if (!qualifies(day)) {
      run = 0;
    } else {
      const expected = new Date(day.date + "T00:00:00Z");
      expected.setUTCDate(expected.getUTCDate() - 1);
      run = previous === expected.toISOString().slice(0, 10) ? run + 1 : 1;
      best = Math.max(best, run);
    }
    previous = day.date;
  }
  const todayDay = adhkarDayStore.get(today);
  return {
    current,
    best,
    todayMorning: todayDay?.morning ?? false,
    todayEvening: todayDay?.evening ?? false,
  };
}

const MOCK_WORSHIP: WorshipSettings = {
  latitude: 21.4225,
  longitude: 39.8262,
  timezone: "Asia/Riyadh",
  method: "ummAlQura",
  madhab: "shafi",
  highLatitude: "recommended",
  hijriAdjustment: 0,
  configured: true,
};

const MOCK_HIJRI: HijriDate = {
  year: 1448,
  month: 6,
  day: 15,
  monthName: "جمادى الآخرة",
  monthNameEn: "Jumada al-Thani",
  dayName: "الأربعاء",
  dayNameEn: "Wednesday",
  formatted: "15 جمادى الآخرة 1448 هـ",
};

function mockPrayerLog(date: string): PrayerLog {
  return (
    prayerLogStore.get(date) ?? {
      date,
      fajr: false,
      dhuhr: false,
      asr: false,
      maghrib: false,
      isha: false,
      excused: false,
    }
  );
}

function mockStreak(): PrayerStreak {
  const logs = [...prayerLogStore.values()].sort((a, b) => a.date.localeCompare(b.date));
  const complete = (log?: PrayerLog) =>
    !!log && ["fajr", "dhuhr", "asr", "maghrib", "isha"].every((k) => log[k as keyof PrayerLog] === true);
  const quality = (log?: PrayerLog) => complete(log) || !!log?.excused;
  const today = todayKey();
  let current = 0;
  let cursor = new Date(today + "T00:00:00Z");
  if (!quality(prayerLogStore.get(today))) cursor.setUTCDate(cursor.getUTCDate() - 1);
  while (quality(prayerLogStore.get(cursor.toISOString().slice(0, 10)))) {
    current += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }
  let best = 0;
  let run = 0;
  let previous = "";
  for (const log of logs) {
    if (!quality(log)) {
      run = 0;
    } else {
      const expected = new Date(log.date + "T00:00:00Z");
      expected.setUTCDate(expected.getUTCDate() - 1);
      run = previous === expected.toISOString().slice(0, 10) ? run + 1 : 1;
      best = Math.max(best, run);
    }
    previous = log.date;
  }
  const day = mockPrayerLog(today);
  return {
    current,
    best,
    todayComplete: complete(day),
    todayExcused: day.excused,
    todayCount: ["fajr", "dhuhr", "asr", "maghrib", "isha"].filter(
      (k) => day[k as keyof PrayerLog] === true,
    ).length,
  };
}

export function mockApi() {
  return {
    async surahs() {
      return SURAHS;
    },
    async reciters() {
      return RECITERS;
    },
    async moshafTracks(reciterId: number, moshafId?: number) {
      const reciter = RECITERS.find((r) => r.id === reciterId) ?? RECITERS[0];
      const moshaf = reciter.moshafs.find((m) => m.id === moshafId) ?? reciter.moshafs[0];
      const base = moshaf.server.endsWith("/") ? moshaf.server : moshaf.server + "/";
      return moshaf.surahs
        .map((n) => {
          const meta = SURAHS.find((s) => s.number === n);
          if (!meta) return null;
          return {
            id: `mp3quran:${moshaf.id}-${n}`,
            provider: "mp3quran",
            providerId: `${moshaf.id}-${n}`,
            title: meta.name,
            artist: reciter.name,
            album: moshaf.name,
            subtitle: `${moshaf.name} · ${meta.ayahs} آية`,
            streamUrl: base + pad(n) + ".mp3",
            kind: "quran" as const,
            attribution: `تلاوة ${reciter.name} — mp3quran.net`,
          };
        })
        .filter(Boolean) as Track[];
    },
    async quranRadios() {
      return STATIONS.slice(0, 6).map((s, i) => ({
        ...s,
        id: "mp3quran-radio:" + i,
        provider: "mp3quran-radio",
        title: "إذاعة القرآن الكريم " + (i + 1),
        artist: "إذاعة القرآن الكريم",
      }));
    },
    async radios(limit = 80) {
      return STATIONS.slice(0, limit);
    },
    async search(query: string): Promise<SearchResults> {
      const q = query.trim();
      return {
        reciters: RECITERS.filter((r) => r.name.includes(q)),
        surahs: SURAHS.filter((s) => s.name.includes(q) || s.englishName.includes(q)),
        tracks: STATIONS.filter((s) => s.title.includes(q)),
      };
    },
    async recent() {
      return [] as Track[];
    },
    async recordPlay() {},
    async ayahReciters() {
      return AYAH_RECITERS;
    },
    async ayahTracks(surahNumber: number, reciterId: string) {
      const reciter = AYAH_RECITERS.find((r) => r.id === reciterId) ?? AYAH_RECITERS[0];
      const meta = SURAHS.find((s) => s.number === surahNumber);
      if (!meta) return [] as Track[];
      const short = meta.name.replace(/^سُورَةُ\s*/, "");
      return Array.from({ length: meta.ayahs }, (_, i) => {
        const digits = `${pad(surahNumber)}${pad(i + 1)}`;
        return {
          id: `everyayah:${reciter.id}:${digits}`,
          provider: "everyayah",
          providerId: `${reciter.id}:${digits}`,
          title: meta.name,
          artist: reciter.name,
          album: meta.name,
          subtitle: `${short} · آية ${i + 1}`,
          streamUrl: `https://everyayah.com/data/${reciter.id}/${digits}.mp3`,
          kind: "quran" as const,
          attribution: `تلاوة ${reciter.name} — everyayah.com`,
        };
      });
    },
    async surahText(surahNumber: number, _translation = false): Promise<Ayah[]> {
      const meta = SURAHS.find((s) => s.number === surahNumber);
      const count = meta?.ayahs ?? 0;
      const text =
        surahNumber === 1
          ? FATIHA
          : Array.from({ length: count }, () => "نص الآية غير متاح في وضع المعاينة داخل المتصفح.");
      return text.map((t, i) => ({
        number: i + 1,
        surah: surahNumber,
        text: t,
        juz: 1,
        page: 1,
        bismillah:
          i === 0 && surahNumber !== 1 && surahNumber !== 9
            ? "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
            : undefined,
        sajda: false,
      }));
    },
    async juzAyahs(juz: number, _translation = false): Promise<Ayah[]> {
      const entry = JUZS.find((item) => item.number === juz);
      if (!entry) return [];
      const ayahs = await this.surahText(entry.surah);
      return ayahs.filter((ayah) => ayah.number >= entry.ayah);
    },
    async juzs(): Promise<Juz[]> {
      return JUZS;
    },
    async quranPages(): Promise<QuranPage[]> {
      return [
        { number: 1, surah: 1, ayah: 1 },
        { number: 2, surah: 2, ayah: 1 },
        { number: 604, surah: 112, ayah: 1 },
      ];
    },
    async dailyAyah(_date?: string): Promise<Ayah> {
      const ayahs = await this.surahText(1);
      return ayahs[0];
    },
    async quranBookmarks(): Promise<QuranBookmark[]> {
      return [...quranBookmarkStore.values()].sort((a, b) => b.createdAt - a.createdAt);
    },
    async addQuranBookmark(surah: number, ayah: number): Promise<QuranBookmark> {
      const key = `${surah}:${ayah}`;
      const existing = quranBookmarkStore.get(key);
      if (existing) return existing;
      const bookmark = { surah, ayah, createdAt: Date.now() };
      quranBookmarkStore.set(key, bookmark);
      return bookmark;
    },
    async removeQuranBookmark(surah: number, ayah: number) {
      quranBookmarkStore.delete(`${surah}:${ayah}`);
    },
    async readerPosition(): Promise<ReaderPosition | null> {
      return readerPositionStore;
    },
    async saveReaderPosition(surah: number, ayah: number): Promise<ReaderPosition> {
      readerPositionStore = { surah, ayah, updatedAt: Date.now() };
      return readerPositionStore;
    },
    async memorized(surahNumber: number) {
      return memorized.get(surahNumber) ?? [];
    },
    async saveMemorized(surahNumber: number, marks: number[]) {
      memorized.set(surahNumber, [...marks]);
    },
    async savePosition(surahNumber: number, reciterId: string, lastAyah: number) {
      positions.set(`${surahNumber}:${reciterId}`, lastAyah);
    },
    async memorization(): Promise<Memorization[]> {
      return [...memorized.entries()].map(([surah, marks]) => ({
        surah,
        memorized: marks,
        updatedAt: Date.now(),
      }));
    },
    async position(surahNumber: number, reciterId: string) {
      return positions.get(`${surahNumber}:${reciterId}`) ?? null;
    },
    async exploreCc(query: string, section: string, limit = 24) {
      const samples = [
        { title: "معاينة موسيقى ١", artist: "فنان تجريبي", license: "CC BY" },
        { title: "معاينة موسيقى ٢", artist: "فنان تجريبي", license: "CC BY-SA" },
        { title: "معاينة موسيقى ٣", artist: "فنان تجريبي", license: "CC0" },
        { title: "نشيد تجريبي ١", artist: "منشد تجريبي", license: "CC BY-NC" },
        { title: "نشيد تجريبي ٢", artist: "منشد تجريبي", license: "Public domain" },
      ];
      const q = query.trim();
      return samples
        .filter((s) => (section === "all" ? true : section === "music" ? s.title.includes("موسيقى") : s.title.includes("نشيد")))
        .filter((s) => !q || s.title.includes(q) || s.artist.includes(q))
        .slice(0, limit)
        .map((s, i) => ({
          id: `openverse:preview-${i}`,
          provider: "openverse",
          providerId: `preview-${i}`,
          title: s.title,
          artist: s.artist,
          durationS: 6,
          streamUrl: "https://everyayah.com/data/Alafasy_128kbps/001001.mp3",
          kind: (s.title.includes("نشيد") ? "anasheed" : "music") as Track["kind"],
          license: s.license,
          licenseUrl: "https://creativecommons.org/licenses/",
          attribution: `${s.artist} — ${s.license} · بيانات تجريبية`,
        }));
    },
    async settings() {
      return [] as [string, string][];
    },
    async setSetting() {},
    async appInfo(): Promise<AppInfo> {
      return {
        version: "0.1.0-dev",
        providers: ["mp3quran", "mp3quran-radio", "radiobrowser", "everyayah"],
        countries: ["SA", "EG", "AE"],
      };
    },

    async worshipSettings(): Promise<WorshipSettings> {
      return MOCK_WORSHIP;
    },
    async setWorshipSettings(settings: WorshipSettings): Promise<WorshipSettings> {
      Object.assign(MOCK_WORSHIP, settings, { configured: true });
      return MOCK_WORSHIP;
    },
    async prayerDay(date?: string): Promise<PrayerDay> {
      const day = date ?? todayKey();
      const now = new Date();
      const minutesNow = now.getHours() * 60 + now.getMinutes();
      const rows: [string, string, number][] = [
        ["fajr", "الفجر", 5 * 60],
        ["sunrise", "الشروق", 6 * 60 + 30],
        ["dhuhr", "الظهر", 12 * 60 + 15],
        ["asr", "العصر", 15 * 60 + 30],
        ["maghrib", "المغرب", 18 * 60 + 5],
        ["isha", "العشاء", 19 * 60 + 35],
      ];
      const clock = (minutes: number) =>
        `${String(Math.floor(minutes / 60)).padStart(2, "0")}:${String(minutes % 60).padStart(2, "0")}`;
      const iso = (date: string, minutes: number) =>
        `${date}T${clock(minutes)}:00`;
      const times = rows.map(([key, name, minutes]) => ({
        key,
        name,
        time: clock(minutes),
        iso: iso(day, minutes),
        minutes,
        passed: minutes <= minutesNow,
      }));
      const upcoming = times.find((time) => time.minutes > minutesNow);
      const tomorrow = new Date(day + "T00:00:00");
      tomorrow.setDate(tomorrow.getDate() + 1);
      const tomorrowKey = `${tomorrow.getFullYear()}-${String(tomorrow.getMonth() + 1).padStart(
        2,
        "0",
      )}-${String(tomorrow.getDate()).padStart(2, "0")}`;
      const next = upcoming
        ? { ...upcoming, passed: false }
        : {
            key: "fajr",
            name: "الفجر",
            time: "05:00",
            iso: iso(tomorrowKey, 5 * 60),
            minutes: 5 * 60,
            passed: false,
          };
      const remainingS = upcoming
        ? Math.max(0, (upcoming.minutes - minutesNow) * 60)
        : Math.max(0, (24 * 60 - minutesNow + 5 * 60) * 60);
      return {
        date: day,
        timezone: MOCK_WORSHIP.timezone,
        times,
        next,
        remainingS,
        qibla: 137.1,
        hijri: MOCK_HIJRI,
        now: now.toISOString(),
      };
    },
    async hijriDate(): Promise<HijriDate | null> {
      return MOCK_HIJRI;
    },
    async qibla(): Promise<QiblaInfo> {
      return {
        bearing: 137.1,
        latitude: MOCK_WORSHIP.latitude,
        longitude: MOCK_WORSHIP.longitude,
      };
    },
    async prayerLog(date: string): Promise<PrayerLog> {
      return mockPrayerLog(date);
    },
    async prayerLogs(): Promise<PrayerLog[]> {
      return [...prayerLogStore.values()].sort((a, b) => a.date.localeCompare(b.date));
    },
    async setPrayerDone(date: string, prayer: string, done: boolean): Promise<PrayerLog> {
      const log = { ...mockPrayerLog(date) };
      if (prayer in log) (log as unknown as Record<string, boolean>)[prayer] = done;
      prayerLogStore.set(date, log);
      return log;
    },
    async setPrayerExcused(date: string, excused: boolean): Promise<PrayerLog> {
      const log = { ...mockPrayerLog(date), excused };
      prayerLogStore.set(date, log);
      return log;
    },
    async prayerStreak(): Promise<PrayerStreak> {
      return mockStreak();
    },

    async adhkarProgress(date?: string): Promise<AdhkarProgress[]> {
      return mockAdhkarProgress(date ?? todayKey());
    },
    async adhkarDay(date?: string): Promise<AdhkarDay> {
      return mockAdhkarDay(date ?? todayKey());
    },
    async setAdhkarRemaining(
      date: string,
      categoryId: string,
      itemId: string,
      remaining: number,
    ): Promise<AdhkarProgress> {
      const map = adhkarProgressStore.get(date) ?? new Map<string, number>();
      const value = Math.max(0, Math.min(1000, Math.floor(remaining)));
      map.set(`${categoryId}::${itemId}`, value);
      adhkarProgressStore.set(date, map);
      return { date, categoryId, itemId, remaining: value };
    },
    async markAdhkarDone(date: string, categoryId: string): Promise<AdhkarDay> {
      if (categoryId !== "morning" && categoryId !== "evening") {
        return mockAdhkarDay(date);
      }
      const day = { ...mockAdhkarDay(date) };
      if (categoryId === "morning") day.morning = true;
      if (categoryId === "evening") day.evening = true;
      adhkarDayStore.set(date, day);
      return day;
    },
    async clearAdhkarCategory(date: string, categoryId: string): Promise<AdhkarDay> {
      const map = adhkarProgressStore.get(date);
      if (map) {
        for (const key of [...map.keys()]) {
          if (key.startsWith(`${categoryId}::`)) map.delete(key);
        }
      }
      const day = { ...mockAdhkarDay(date) };
      if (categoryId === "morning") day.morning = false;
      if (categoryId === "evening") day.evening = false;
      adhkarDayStore.set(date, day);
      return day;
    },
    async adhkarStreak(): Promise<AdhkarStreak> {
      return mockAdhkarStreak();
    },

    async favorites(_limit?: number) {
      return [...favoriteSet.values()];
    },
    async favoriteIds() {
      return [...favoriteSet.keys()];
    },
    async addFavorite(track: Track) {
      favoriteSet.set(track.id, track);
    },
    async removeFavorite(trackId: string) {
      favoriteSet.delete(trackId);
    },
    async playlists(): Promise<Playlist[]> {
      return [...playlistStore.values()].map((p) => ({
        ...p.meta,
        trackCount: p.tracks.length,
      }));
    },
    async createPlaylist(name: string): Promise<Playlist> {
      const meta: Playlist = {
        id: `pl-${Date.now()}-${playlistStore.size}`,
        name,
        createdAt: Date.now(),
        trackCount: 0,
      };
      playlistStore.set(meta.id, { meta, tracks: [] });
      return meta;
    },
    async renamePlaylist(playlistId: string, name: string) {
      const entry = playlistStore.get(playlistId);
      if (entry) entry.meta.name = name;
    },
    async deletePlaylist(playlistId: string) {
      playlistStore.delete(playlistId);
    },
    async playlistTracks(playlistId: string) {
      return playlistStore.get(playlistId)?.tracks ?? [];
    },
    async addToPlaylist(playlistId: string, track: Track) {
      const entry = playlistStore.get(playlistId);
      if (entry && !entry.tracks.some((t) => t.id === track.id)) {
        entry.tracks.push(track);
      }
    },
    async removeFromPlaylist(playlistId: string, trackId: string) {
      const entry = playlistStore.get(playlistId);
      if (entry) entry.tracks = entry.tracks.filter((t) => t.id !== trackId);
    },
    async startDownload(_track: Track): Promise<string> {
      throw new Error("Downloads run in the desktop app only");
    },
    async cancelDownload(_trackId: string) {
      return false;
    },
    async getHotkeys(): Promise<HotkeyMap> {
      return {
        toggle: "Ctrl+Alt+Space",
        next: "Ctrl+Alt+ArrowRight",
        previous: "Ctrl+Alt+ArrowLeft",
      };
    },
    async setHotkeys(hotkeys: HotkeyMap) {
      return hotkeys;
    },
    async downloads(): Promise<DownloadRow[]> {
      return [...downloadsStore.values()];
    },
    async deleteDownload(trackId: string) {
      downloadsStore.delete(trackId);
    },
    async importFolder(): Promise<ImportSummary> {
      throw new Error("Local import runs in the desktop app only");
    },
    async localTracks() {
      return [] as Track[];
    },
    async forgetLocalTrack(_trackId: string) {},
  };
}
