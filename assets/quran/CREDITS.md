# Credits & data provenance

This engine would not exist without the people and projects below. Please preserve this attribution in any redistribution. Each upstream app keeps its own full credits in its repository — [Al-Islam](https://github.com/TheAbubakrAbu/Al-Islam-iOS/blob/main/CREDITS.md) · [Al-Adhan](https://github.com/TheAbubakrAbu/Al-Adhan-iOS/blob/main/CREDITS.md) · [Al-Quran](https://github.com/TheAbubakrAbu/Al-Quran-iOS/blob/main/CREDITS.md).

<a href="https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655?platform=iphone">
  <img src="Logo.png" alt="Logo" width="120" style="border-radius:10px;"/>
</a>

## Upstream project

All data and algorithms in this repository are extracted from the open-source **Al-Islam | Islamic Pillars** app, with full credit to its author:

- **Author:** Abubakr Elmallah (أبوبكر الملاح)
- **Project:** Al-Islam | Islamic Pillars — <https://github.com/TheAbubakrAbu/Al-Islam-iOS>
- **License:** MIT (© 2025 Abubakr Elmallah)
- **App Store:** <https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655>
- **Website:** <https://abubakrelmallah.com/>

The tajweed engine specification, the search/sort/juz/page logic, the Arabic-alphabet data, and the reciter directory are ports of the Swift implementation in that project (`QuranData.swift`, `QuranStructs.swift`, `TajweedRules.swift`, `TajweedView.swift`, `ArabicLetters.swift`, `ArabicView.swift`, `QuranPlayer.swift`, `Settings.swift`, `Globals.swift`).

## Quran text & readings

- **Quranic Arabic text and all qiraat / riwayaat data** — **quran-data-kfgqpc (KFGQPC)** — <https://github.com/thetruetruth/quran-data-kfgqpc>. The default text is the **Hafs an Asim** Uthmani script; alternate readings included: Warsh, Qaloon, ad-Duri, as-Susi, al-Bazzi, Qunbul, Shubah.

> The Quran is the sacred scripture of Islam. The Arabic text must be preserved **exactly** and never altered. Treat it with the respect it is due.

## Translations & transliteration

- **English transliteration** — **Risan Bagja Pradana** (`quran-json`) — <https://github.com/risan/quran-json>
- **Saheeh International** translation — via **Global Quran** — <https://globalquran.com/download/data/>
- **Dr. Mustafa Khattab, *The Clear Quran*** — `textEnglishMustafa`.

These translations are included for study and accessibility. They remain the work and rights of their respective publishers; consult their terms for redistribution beyond fair educational use.

## Surah introductions (`surah-info.json`)

- **Quran.com (Quran Foundation)** chapter info — <https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/get-chapter-info/>. Sources include **Sayyid Abul A'la Maududi** (*Tafhim al-Qur'an*) and **Ibn Ashur** (*al-Tahrir wa al-Tanwir*).

## 99 Names of Allah (`names-of-allah.json`)

- **MyIslam** — <https://myislam.org/99-names-of-allah/>

## Fonts (`data/fonts/`)

- **Uthmani (Hafs) & Qiraat (Qunbul) Uthmanic scripts** — **King Fahd Glorious Quran Printing Complex (KFGQPC)** — <https://qul.tarteel.ai/resources/font/245>, <https://github.com/thetruetruth/quran-data-kfgqpc>
- **Indopak Nastaleeq (Al Mushaf)** — **Ayman Siddiqui and R. Siddiqua** — <https://qul.tarteel.ai/resources/font/242>

The fonts are included for convenience under the terms by which they were published for Quranic use. If you redistribute them, follow the original publishers' terms. See [docs/fonts.md](docs/fonts.md).

## Tajweed teaching content

- The detailed rule explanations in [docs/tajweed-rules-explained.md](docs/tajweed-rules-explained.md) are adapted from the "Tajweed Foundations" lessons in the Al-Islam app.
- **Stopping / pausing (waqf) sign meanings** — **Studio Arabiya** — <https://studioarabiya.com/blog/tajweed-rules-stopping-pausing-signs/>

## Audio (URLs only — no audio files are bundled)

- **Full-surah recitations** — **MP3 Quran** — <https://mp3quran.net/eng>
- **Ayah-by-ayah recitations** — **Al Quran (alquran.cloud)** — <https://alquran.cloud/cdn>

This engine constructs URLs to these third-party services; it neither hosts nor redistributes audio. Respect each provider's terms of use.

## A note on intent

This project — like the apps it draws from, **Al-Islam**, **Al-Adhan**, and **Al-Quran** — is offered as *sadaqah jariyah*: a continuing charity for the benefit of the Muslim community and anyone building tools to read, learn, and listen to the Quran. If it helps you, please keep the chain of attribution intact and consider contributing improvements back, so the reward continues for everyone who came before you.

> *"When a person dies, all their deeds end except three: a continuing charity (sadaqah jariyah), beneficial knowledge, or a righteous child who prays for them."* — Prophet Muhammad ﷺ (Sahih Muslim)
