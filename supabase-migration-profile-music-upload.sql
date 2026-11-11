-- Permite upload de músicas nos perfis A1M (até 15 MB).
update storage.buckets
set file_size_limit = 15728640,
    allowed_mime_types = array[
      'image/png','image/jpeg','image/webp',
      'audio/mpeg','audio/mp3','audio/ogg','audio/wav','audio/x-wav',
      'audio/mp4','audio/aac','audio/x-m4a'
    ]
where id = 'a1m-media';
