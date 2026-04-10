# Linguist Submission

Draft materials for adding Blink to [github-linguist/linguist](https://github.com/github-linguist/linguist).

## Status

| Requirement | Status |
|---|---|
| MIT LICENSE | Done |
| TextMate grammar (`syntaxes/blink.tmLanguage.json`) | Done |
| Sample files (`samples/Blink/`) | Done |
| languages.yml draft (`linguist/languages.yml`) | Done |
| 2,000+ `.bl` files on GitHub (excl. forks) | **Not yet** |

## `.bl` Extension

No existing language in Linguist uses `.bl`. No disambiguation heuristics needed.

## Submission Steps

When the usage threshold is met:

1. Fork `github-linguist/linguist`
2. Add the grammar: `script/add-grammar <blink-grammar-repo-url>`
3. Copy samples to `samples/Blink/`
4. Add the entry from `languages.yml` to `lib/linguist/languages.yml` (alphabetical order under "B")
5. Run `script/update-ids` to generate `language_id`
6. Open PR using the Linguist PR template, linking GitHub search results for `.bl` files
