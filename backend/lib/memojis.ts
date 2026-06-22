// Curated memoji set from alohe/memojis (github.com/alohe/memojis)
// Served via jsDelivr CDN: https://cdn.jsdelivr.net/gh/alohe/memojis@main/png/<file>
// URL pattern verified: each URL returns a PNG image.

const BASE = "https://cdn.jsdelivr.net/gh/alohe/memojis@main/png";

export const MEMOJIS: { id: string; url: string }[] = [
  // memo series — classic Apple-style memoji faces
  { id: "memo_1",  url: `${BASE}/memo_1.png`  },
  { id: "memo_2",  url: `${BASE}/memo_2.png`  },
  { id: "memo_3",  url: `${BASE}/memo_3.png`  },
  { id: "memo_4",  url: `${BASE}/memo_4.png`  },
  { id: "memo_5",  url: `${BASE}/memo_5.png`  },
  { id: "memo_6",  url: `${BASE}/memo_6.png`  },
  { id: "memo_7",  url: `${BASE}/memo_7.png`  },
  { id: "memo_8",  url: `${BASE}/memo_8.png`  },
  // notion series — clean, minimal style
  { id: "notion_1",  url: `${BASE}/notion_1.png`  },
  { id: "notion_2",  url: `${BASE}/notion_2.png`  },
  { id: "notion_3",  url: `${BASE}/notion_3.png`  },
  { id: "notion_4",  url: `${BASE}/notion_4.png`  },
  { id: "notion_5",  url: `${BASE}/notion_5.png`  },
  { id: "notion_6",  url: `${BASE}/notion_6.png`  },
  // 3d series — rendered 3-D faces
  { id: "3d_1", url: `${BASE}/3d_1.png` },
  { id: "3d_2", url: `${BASE}/3d_2.png` },
  { id: "3d_3", url: `${BASE}/3d_3.png` },
  { id: "3d_4", url: `${BASE}/3d_4.png` },
  { id: "3d_5", url: `${BASE}/3d_5.png` },
  // upstream series — expressive style
  { id: "upstream_1",  url: `${BASE}/upstream_1.png`  },
  { id: "upstream_2",  url: `${BASE}/upstream_2.png`  },
  { id: "upstream_3",  url: `${BASE}/upstream_3.png`  },
  { id: "upstream_4",  url: `${BASE}/upstream_4.png`  },
];

export const DEFAULT_MEMOJI_ID = "memo_1";
