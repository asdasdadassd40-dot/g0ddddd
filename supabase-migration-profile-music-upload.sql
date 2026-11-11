-- A1M: aceita somente MP3 de até 500 MB no bucket de mídia.
-- O limite global do projeto Supabase também deve ser >= 500 MB.
update storage.buckets
set file_size_limit = 524288000,
    allowed_mime_types = array[
      'image/png','image/jpeg','image/webp','audio/mpeg'
    ]
where id = 'a1m-media';
