"use strict";
const hexElderDeck = (nums) => nums.map((n) => "WE-" + String(n).padStart(3, "0"));
const HEX_ELDER_DECKS = {
  "pebble-patrol": [1, 1, 3, 3, 4, 4, 5, 5, 7, 7, 19, 19, 34, 34, 35, 35, 36, 36, 42, 42],
  "burrow-watch": [8, 8, 9, 9, 10, 10, 12, 12, 15, 15, 17, 17, 23, 23, 29, 29, 33, 33, 37, 37],
  "ram-raiders": [2, 2, 5, 5, 13, 13, 14, 14, 16, 16, 34, 34, 35, 35, 42, 42, 30, 30, 46, 46],
  "bloodfist-horde": [4, 4, 3, 3, 19, 19, 24, 24, 26, 26, 2, 2, 21, 22, 22, 23, 34, 34, 46, 46],
  "cloudcarriage-guard": [
    8, 8, 10, 10, 12, 12, 25, 25, 27, 27, 18, 18, 20, 23, 23, 30, 30, 37, 37, 44,
  ],
  "rootbound-alliance": [
    15, 15, 8, 8, 24, 24, 25, 25, 18, 18, 17, 17, 32, 32, 38, 38, 39, 39, 49, 49,
  ],
  "fisduum-coven": [3, 3, 11, 11, 19, 19, 2, 2, 26, 26, 7, 7, 28, 28, 48, 48, 36, 36, 43, 44],
  "seraphic-warhost": [45, 26, 26, 24, 24, 2, 2, 7, 7, 15, 15, 8, 46, 46, 22, 22, 28, 47, 49, 44],
};
const HEX_ELDER_NAMES = {
  "pebble-patrol": "Pebble Patrol",
  "burrow-watch": "Burrow Watch",
  "ram-raiders": "Ram Raiders",
  "bloodfist-horde": "Bloodfist Horde",
  "cloudcarriage-guard": "Cloudcarriage Guard",
  "rootbound-alliance": "Rootbound Alliance",
  "fisduum-coven": "Fis’Duum Coven",
  "seraphic-warhost": "Seraphic Warhost",
};
for (const [id, cards] of Object.entries(HEX_ELDER_DECKS)) {
  HEX_BOT_DECKS[id] = hexElderDeck(cards);
  HEX_BOT_NAMES[id] = HEX_ELDER_NAMES[id];
}
Object.assign(HEX_CARD_ABILITY_POWER, {
  201: 2,
  202: 2,
  203: 2,
  204: 2,
  205: 1,
  206: 0,
  207: 2,
  208: 1,
  209: 2,
  210: 2,
  211: 3,
  212: 2,
  213: 0,
  214: -1,
  215: 1,
  216: 2,
  217: 1,
  218: 6,
  219: 3,
  224: 4,
  225: 4,
  226: 5,
  227: 5,
  245: 5,
});
Object.assign(HEX_SUPPORT_POWER, {
  220: 6,
  221: 6,
  222: 7,
  223: 7,
  228: 12,
  229: 5,
  230: 8,
  231: 8,
  232: 8,
  233: 4,
  234: 6,
  235: 6,
  236: 8,
  237: 5,
  238: 7,
  239: 7,
  240: 7,
  241: 5,
  242: 7,
  243: 10,
  244: 12,
  246: 10,
  247: 14,
  248: 8,
  249: 12,
});
