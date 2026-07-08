-- Migration V024: Backfill list-card summaries from existing product descriptions.
update products
set short_description = left(regexp_replace(description, '\s+', ' ', 'g'), 160)
where short_description is null
  and description is not null
  and btrim(description) <> '';
