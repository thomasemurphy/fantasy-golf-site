# Normalizes golfer names so they can be compared across feeds (ESPN, PGA Tour,
# our Golfer table). Downcases, strips accents, removes dots/punctuation, and
# collapses whitespace so "J.J. Spaun", "JJ Spaun" and "Niklas Nørgaard" /
# "Niklas Norgaard" resolve to the same key.
module GolferName
  ACCENT_MAP = {
    "À" => "A", "Á" => "A", "Â" => "A", "Ã" => "A", "Ä" => "A", "Å" => "A",
    "à" => "a", "á" => "a", "â" => "a", "ã" => "a", "ä" => "a", "å" => "a",
    "È" => "E", "É" => "E", "Ê" => "E", "Ë" => "E",
    "è" => "e", "é" => "e", "ê" => "e", "ë" => "e",
    "Ì" => "I", "Í" => "I", "Î" => "I", "Ï" => "I",
    "ì" => "i", "í" => "i", "î" => "i", "ï" => "i",
    "Ò" => "O", "Ó" => "O", "Ô" => "O", "Õ" => "O", "Ö" => "O", "Ø" => "O",
    "ò" => "o", "ó" => "o", "ô" => "o", "õ" => "o", "ö" => "o", "ø" => "o",
    "Ù" => "U", "Ú" => "U", "Û" => "U", "Ü" => "U",
    "ù" => "u", "ú" => "u", "û" => "u", "ü" => "u",
    "Ý" => "Y", "ý" => "y", "ÿ" => "y",
    "Ñ" => "N", "ñ" => "n",
    "Ç" => "C", "ç" => "c",
    "ß" => "ss"
  }.freeze

  # Removes accents only (preserving case/punctuation) — used where the original
  # name form should be kept, e.g. matching against the Golfer table.
  def self.strip_accents(str)
    str.to_s.chars.map { |c| ACCENT_MAP[c] || c }.join
  end

  # Full comparison key: accent-stripped, lowercased, punctuation removed,
  # whitespace collapsed. Use for matching the same person across feeds.
  def self.key(str)
    strip_accents(str)
      .downcase
      .gsub(/[^a-z0-9 ]/, "")  # drop dots, apostrophes, hyphens, etc.
      .split
      .join(" ")
  end
end
