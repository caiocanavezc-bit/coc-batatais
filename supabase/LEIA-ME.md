# Mural dos aprovados: como ligar o Supabase

O mural (`aprovados.html` e a seção da página inicial) e o painel (`painel-aprovados.html`) guardam os aprovados e as fotos no Supabase, que é gratuito. A configuração é feita uma vez só.

## 1. Criar o projeto

1. Entre em https://supabase.com e crie uma conta.
2. Clique em **New project**, dê o nome `coc-batatais`, crie uma senha do banco (guarde-a) e escolha a região **South America (São Paulo)**.

## 2. Criar a tabela, a pasta das fotos e as permissões

1. No menu lateral, abra **SQL Editor** e clique em **New query**.
2. Abra o arquivo `supabase/setup.sql`, troque `responsavel@exemplo.com` pelo e-mail de quem vai cadastrar os aprovados (um por linha, se forem vários) e cole o arquivo inteiro.
3. Clique em **Run**. Deve aparecer "Success".

## 3. Fechar o cadastro para o público

Em **Authentication > Sign In / Providers**, desligue **Allow new users to sign up**. Assim ninguém consegue criar uma conta sozinho.

## 4. Criar o login do responsável

1. Em **Authentication > Users**, clique em **Add user > Create new user**.
2. Use o mesmo e-mail colocado no `setup.sql`, crie uma senha e marque **Auto Confirm User**.

Só quem está na lista do `setup.sql` consegue publicar ou remover. Para incluir outra pessoa: crie o usuário (passo 4) e rode no SQL Editor:

```sql
insert into public.admins (email) values ('novo@email.com');
```

## 5. Ligar o site ao Supabase

1. Em **Project Settings > API** (ou **Data API**), copie o **Project URL** e a chave **anon public**.
2. Cole os dois em `assets/supabase-config.js`.
3. Publique o site.

A chave `anon public` pode ficar no site, porque quem protege os dados são as regras do `setup.sql`. Nunca use a chave `service_role` no site.

## Uso no dia a dia

- Painel: `https://SEU-SITE/painel-aprovados.html`. Ele não aparece no menu do site.
- Cada aprovado cadastrado aparece no mural na hora, sem precisar publicar o site de novo.
- Antes de publicar a foto de um aluno, tenha a autorização dele (ou dos pais, se for menor de idade), conforme a LGPD.
