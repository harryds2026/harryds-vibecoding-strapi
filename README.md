# Strapi CMS

Strapi CMS with PostgreSQL, pre-configured for one-click deployment on Zeabur.

[![Deploy on Zeabur](https://zeabur.com/button.svg)](https://zeabur.com/templates/7YJAKW)

## 1) One-click Deploy (No Code)

Use this when you only need to manage content (articles, images, text):

1. Click the deploy button above
2. Enter your domain name
3. Click **Deploy**
4. Open `https://<your-domain>.zeabur.app/admin`
5. Create your admin account and start managing content

PostgreSQL and required environment variables are provisioned automatically.

## 2) Edit Content Types (Schema) Locally

Strapi in production does not allow editing content types directly in cloud admin.
To change content types, use local development and push code updates.

```bash
cp .env.example .env
npm install
npm run develop
```

Open [http://localhost:1337/admin](http://localhost:1337/admin) to access the admin panel.

After updating your content types:

```bash
git add .
git commit -m "Update content types"
git push
```

Zeabur will redeploy automatically with your new schema.

## 3) Student Self-Service Template Automation

If each student uses their own GitHub repo, run this script in their forked repo.
It resolves their GitHub repo ID and creates/updates their own Zeabur template.

Prerequisites (one-time):

```bash
gh auth login
```

The script will prompt Zeabur login in browser when needed.

Create a new template:

```bash
npm run template:publish -- --repo <owner>/<repo>
```

Update an existing template:

```bash
npm run template:publish -- --repo <owner>/<repo> --code <template-code>
```

Example:

```bash
npm run template:publish -- --repo harrychuang/harryds-vibecoding-strapi --code 7YJAKW
```

## Environment Variables

See [`.env.example`](.env.example) for a full list of configurable variables. Key variables:

| Variable | Description |
|---|---|
| `DATABASE_CLIENT` | Database type (`sqlite` or `postgres`) |
| `DATABASE_URL` | PostgreSQL connection string |
| `APP_KEYS` | Application keys (comma-separated) |
| `ADMIN_JWT_SECRET` | Secret for admin JWT tokens |
| `JWT_SECRET` | Secret for user JWT tokens |

## Learn More

- [Strapi Documentation](https://docs.strapi.io)
- [Strapi CLI Reference](https://docs.strapi.io/dev-docs/cli)
- [Zeabur Documentation](https://zeabur.com/docs)
