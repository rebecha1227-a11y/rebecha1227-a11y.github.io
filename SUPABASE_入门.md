# Supabase 云端同步 — 从零配置（邮箱 + 密码）

按顺序做即可。完成后，同一账号可在手机、电脑等多台设备同步聊天记录与设置。

---

## 你需要准备

- 常用邮箱（注册 Supabase + 在本应用里登录）
- 能改 `index.html` 并重新打开网页（GitHub Pages 推送后会自动更新）

---

## 第 1 步：在 Supabase 创建项目

1. 打开 [https://supabase.com](https://supabase.com) ，注册并登录。
2. 控制台点 **New project**。
3. 填写项目名称、**数据库密码**（自己保存好）、区域（建议选离你近的）。
4. 等待项目创建完成（约 1～2 分钟）。

---

## 第 2 步：建数据表与安全规则（必须执行）

1. 左侧打开 **SQL Editor** → **New query**。
2. **只复制 SQL 本身**，粘贴进编辑器，点 **Run**。  
   **不要**把 Markdown 里的 `` ```sql `` 或结尾的 `` ``` `` 三反引号粘进去，否则会报 `syntax error at or near "```"`（你截图里的就是这种错误）。  
   **更简单**：直接打开本仓库里的 **`supabase_schema.sql`**，全选复制，再粘贴到 SQL Editor（该文件里没有反引号）。

```sql
create table public.aichat_user_data (
  user_id uuid primary key references auth.users (id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.aichat_user_data enable row level security;

create policy "aichat_select_own"
  on public.aichat_user_data for select
  using (auth.uid() = user_id);

create policy "aichat_insert_own"
  on public.aichat_user_data for insert
  with check (auth.uid() = user_id);

create policy "aichat_update_own"
  on public.aichat_user_data for update
  using (auth.uid() = user_id);
```

3. 底部应显示成功；表名必须是 **`aichat_user_data`**（与网页代码一致）。

---

## 第 3 步：邮箱登录方式（仅自己用可关掉邮件验证）

1. 左侧 **Authentication** → **Providers** → **Email**。
2. **不想收验证码、不想收确认邮件**（只有你一个人用）：把 **Confirm email**（确认邮箱）**关掉**。  
   之后用「邮箱 + 密码」注册完**马上可以登录**，无需打开邮箱。  
   若以后要给他人用或加强安全，再打开 **Confirm email** 即可。
3. 若**开启了邮箱验证**：到 **Authentication** → **URL Configuration**，把 **Site URL** 设为你的站点地址（例如 `https://你的用户名.github.io/仓库名/`），否则邮件里的链接可能无法跳回你的网站。
4. 保存设置。

---

## 第 4 步：把密钥填进 `index.html`

1. 左侧 **Project Settings**（齿轮）→ **API**。
2. 复制 **Project URL**（形如 `https://xxxx.supabase.co`）。
3. 复制 **Project API keys** 里的 **anon public**（**不要**用 `service_role`）。
4. 用编辑器打开本仓库里的 **`index.html`**，搜索：

   - `const SUPABASE_URL`
   - `const SUPABASE_ANON_KEY`

5. 在引号里粘贴，例如：

```javascript
const SUPABASE_URL = 'https://你的项目.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

6. **保存文件**。若用 GitHub Pages：提交并推送，等一两分钟再打开网站。  
7. **刷新页面**（改完密钥后必须重新加载，客户端才会连上 Supabase）。

---

## 第 5 步：在应用里注册 / 登录

1. 打开站点 → 底部 **我** → **Supabase 云端同步**。
2. 输入**邮箱**、**密码**（至少 6 位，按 Supabase 默认规则）。
3. 点 **注册账号**，再 **登录**（若开启了邮箱验证，需先去邮箱点链接）。
4. **第一次登录**若云端已有数据，会弹出选择：

   - **确定**：用**云端**覆盖当前浏览器里的数据（适合新手机拉旧记录）。
   - **取消**：保留**本机**，并把本机数据**上传覆盖云端**（适合本机才是最新时）。

5. 之后你在本机聊天、改设置，保存后大约 **2 秒**会自动上传到云端（需保持已登录）。

### 手动按钮说明

- **本机上传到云端**：立刻把当前快照存到 Supabase。
- **从云端拉取覆盖本机**：用云端整包覆盖本机（操作前建议先到 **导出数据** 做备份）。

---

## 常见问题

| 现象 | 处理 |
|------|------|
| 设置里显示「未配置」 | `SUPABASE_URL` / `SUPABASE_ANON_KEY` 仍为空，或改完未保存、未刷新页面。 |
| `Invalid API key` | 检查是否误填了 **service_role**，应使用 **anon public**。 |
| 同步失败、表里没数据 | 第 2 步 SQL 未成功执行，或表名不是 `aichat_user_data`。 |
| 注册后登录不了 | 若开启了邮箱验证，需先到邮箱确认；或在 Supabase **Authentication → Users** 里查看用户状态。 |
| 脚本加载失败 | 浏览器需能访问 `esm.sh`（用于加载 Supabase 官方 JS）；可换网络或稍后重试。 |

---

## 安全说明（请读）

- 放在网页里的 **anon 公钥**本来就是给浏览器用的；数据安全依赖 **RLS**：每个用户只能读写自己的那一行。
- **绝对不要**把 **`service_role` 密钥**写进 `index.html` 或公开仓库。
- 开启云端后，**整包数据**（含 DeepSeek API Key 等）会存在**你的** Supabase 项目里，请保管好 **Supabase 账号密码** 与 **本应用登录密码**。
