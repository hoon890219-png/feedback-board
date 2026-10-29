# 앱 피드백 보드

로그인 없이 링크만 열면 수정 요청을 남길 수 있는 정적 웹사이트입니다.
데이터는 Supabase, 배포는 Netlify/Vercel/Cloudflare Pages 중 아무 곳이나 쓸 수 있습니다. 모두 무료 요금제로 충분합니다.

- 지인: 링크 접속 → 수정 요청 작성, 진행 현황과 답변 확인 (로그인 없음)
- 개발자(본인): 페이지 맨 아래 "개발자 로그인" → 앱 등록, 상태·답변 수정, 삭제

## 1. Supabase 설정 (약 5분)
1. https://supabase.com 에서 무료 프로젝트를 만듭니다.
2. 왼쪽 메뉴 **SQL Editor** → New query → `supabase/schema.sql` 내용을 전부 붙여넣고 **Run**.
   (맨 아래 `insert into public.admins` 줄의 이메일이 본인 이메일인지 확인하세요.)
3. **Authentication → Users → Add user → Create new user**: 위에서 쓴 이메일과 비밀번호로 계정을 만듭니다. (Auto Confirm User 체크)
4. **Authentication → Sign In / Providers**(또는 Settings)에서 **Allow new users to sign up**을 끕니다.
5. **Project Settings → API**에서 `Project URL`과 `anon public` 키를 복사해 `config.js`에 넣습니다.
   anon 키는 공개되어도 되는 키입니다. 쓰기 권한은 schema.sql의 RLS 정책이 막고 있습니다. **service_role 키는 절대 넣지 마세요.**

## 2. 배포
폴더 안의 `index.html`, `config.js` 두 파일이 사이트의 전부입니다.
- Netlify: https://app.netlify.com/drop 에 폴더를 끌어다 놓으면 바로 주소가 생깁니다.
- Cloudflare Pages / Vercel: 폴더를 업로드하거나 GitHub 저장소를 연결합니다.

## 3. 확인
1. 배포된 주소를 시크릿 창에서 열어 로그인 없이 요청이 등록되는지 확인합니다.
2. 페이지 맨 아래 "개발자 로그인"으로 로그인해 앱을 추가하고 상태를 바꿔봅니다.

## 보안·스팸 메모
- 일반 방문자는 읽기와 "대기 상태 요청 등록"만 가능합니다. 상태/답변 수정, 앱 추가, 삭제는 관리자 이메일로 로그인해야 합니다.
- 숨은 입력칸(봇 차단)과 DB 트리거(1분에 30건 초과 시 차단)로 기본 스팸 방어가 되어 있습니다.
- 스팸이 늘면 Supabase의 CAPTCHA 설정이나 Cloudflare 앞단 보호를 추가하세요.
- 이름과 요청 내용은 링크를 가진 모든 사람에게 보입니다. 개인정보를 적지 말라고 안내해 주세요.
