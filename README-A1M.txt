A1M — SITE + PAINEL DE MEMBROS

O que está implementado
- Cadastro e login por e-mail/senha usando Supabase Auth.
- Perfis públicos sincronizados entre visitantes.
- Um perfil por usuário (restrição UNIQUE no banco).
- Membro: cria o próprio perfil uma vez e pode editar nome, descrição, Discord, Instagram, X, link externo, música, avatar e banner.
- Administrador: pode criar perfis para usuários (informando UUID), editar seu próprio perfil e excluir qualquer perfil.
- Upload de avatar/banner para Supabase Storage (PNG/JPG/WEBP, até 5 MB).
- Permissões validadas no PostgreSQL por RLS; não depende de IP nem de uma senha de administrador no JavaScript.

CONFIGURAÇÃO OBRIGATÓRIA (antes de publicar)
1. Crie um projeto em https://supabase.com/ .
2. Abra SQL Editor e execute todo o arquivo supabase-schema.sql.
3. Em Project Settings > API, copie Project URL e a chave anon/public.
4. Edite supabase-config.js e substitua:
   url: 'https://SEU-PROJETO.supabase.co'
   anonKey: 'COLE_SUA_CHAVE_ANON_PUBLICA_AQUI'
   A chave anon/public é própria para navegador com RLS habilitado. NUNCA use service_role.
5. Publique a pasta na Vercel como projeto estático. O vercel.json já configura fallback.
6. Crie sua conta pelo site. No Supabase, abra Authentication > Users, copie o User UID.
7. No SQL Editor, execute (com seu UUID real):
   insert into public.user_roles(user_id, role) values ('SEU-UUID', 'admin')
   on conflict (user_id) do update set role = 'admin';
8. Saia e entre novamente no site. A conta aparecerá como ADMINISTRADOR.

NOTAS IMPORTANTES
- Sem configurar Supabase, o site visual abre, mas cadastro/login e dados compartilhados não funcionam.
- Para produção, configure confirmação de e-mail e SMTP em Authentication > Providers/SMTP conforme sua necessidade.
- O campo música aceita URL direta pública para arquivo de áudio compatível (por exemplo MP3/OGG); navegadores exigem interação do visitante antes de iniciar áudio.
- Para permitir que o admin crie perfil para outro usuário, informe o UUID desse usuário no campo que aparece no formulário administrativo. A conta de destino deve existir no Supabase Auth.
- A aplicação não contém credenciais secretas. A segurança de papéis e operações é aplicada pelas políticas RLS do banco.


NOVA SEPARAÇÃO DE PERFIS
- A página pública possui duas abas: "Membros A1M" e "Não são da A1M".
- O campo is_member identifica a categoria; os perfis existentes ficam como A1M por padrão.
- Para atualizar um projeto Supabase já configurado, execute supabase-migration-profile-categories.sql no SQL Editor (Database).
- Administradores podem escolher a categoria ao criar ou editar um perfil.
- Para criar um perfil externo pelo painel, o administrador precisa informar o UUID de uma conta existente no Supabase Auth. A tabela mantém um perfil por usuário.
- Membros comuns continuam podendo criar e editar somente o próprio perfil A1M; não podem classificar a si mesmos como externos.

AUTORIZAÇÃO DE CONTAS PARA MEMBROS A1M
- Execute também o arquivo supabase-migration-member-approval.sql no SQL Editor do Supabase.
- Novas contas são registradas automaticamente como "Aguardando".
- No site, entre com a conta administradora e abra Minha conta. A seção "Autorizações de contas" permite Autorizar ou Recusar cada conta.
- Somente contas com status "Autorizada" podem criar um perfil próprio na área Membros A1M. A regra também é aplicada no PostgreSQL/RLS.
- Contas que já existiam quando a migração for executada são adicionadas à lista como pendentes; autorize-as pelo painel.


PERSONALIZAÇÃO DO PERFIL (ATUALIZAÇÃO)
Para habilitar o fundo personalizado, execute no SQL Editor do Supabase o arquivo supabase-migration-profile-background.sql. Cada usuário pode enviar uma imagem de fundo própria (PNG/JPG/WEBP, até 5 MB). Na página pública, o visitante pode tocar, pausar e continuar a música do perfil.
