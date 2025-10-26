# LangChat AI Admin

Web-based admin interface for managing AI model configurations for the LangChat iOS app.

## Features

### 1. AI Model Setup Page (`/`)
Mirrors the iOS AI Setup interface with:
- **Category Selection**: Toggle between Translation, Grammar, and Scoring
- **Model Configuration**: Edit model ID, name, provider, temperature, max tokens
- **Grammar Sensitivity Levels**: Minimal, Moderate, Verbose (only for Grammar category)
- **Master Prompt Editor**: Edit prompts with placeholder support for `{learning_language}` and `{native_language}`
- **Live Updates**: Changes sync directly to Supabase

### 2. AI Model Bindings Page (`/bindings`)
Split view showing:
- **Left Panel**: List of all configured bindings (Translation, Grammar x3 levels, Scoring)
- **Right Panel**: View selected binding's prompt with copy functionality

## Setup

### 1. Configure Supabase

Copy `.env.local.example` to `.env.local`:

```bash
cp .env.local.example .env.local
```

Fill in your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=https://ckhukylfoeofvoxvwwin.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Production Build

```bash
npm run build
npm start
```

## Database Schema

The web admin connects to the `ai_config` table in Supabase:

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| category | TEXT | 'translation', 'grammar', or 'scoring' |
| model_id | TEXT | Model identifier (e.g., 'anthropic/claude-3.5-sonnet') |
| model_name | TEXT | Display name (e.g., 'Claude 3.5 Sonnet') |
| model_provider | TEXT | Provider name (e.g., 'anthropic') |
| prompt_template | TEXT | Base prompt template |
| grammar_level_1_prompt | TEXT | Minimal sensitivity prompt (grammar only) |
| grammar_level_2_prompt | TEXT | Moderate sensitivity prompt (grammar only) |
| grammar_level_3_prompt | TEXT | Verbose sensitivity prompt (grammar only) |
| temperature | FLOAT | Model temperature (0.0-1.0) |
| max_tokens | INT | Maximum tokens in response |
| is_active | BOOLEAN | Enable/disable configuration |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

## Usage

### Editing Model Configuration

1. Select a category (Translation, Grammar, or Scoring)
2. Update model details (ID, name, provider, temperature, max tokens)
3. For Grammar category, select sensitivity level (Minimal, Moderate, Verbose)
4. Edit the master prompt in the text area
5. Click "Save Configuration" to persist changes to Supabase

### Viewing Bindings

1. Navigate to "AI Model Bindings" page
2. Click on any binding in the left panel
3. View the prompt in the right panel
4. Use the Copy button to copy prompts to clipboard

## Architecture

- **Framework**: Next.js 15 with App Router
- **Styling**: Tailwind CSS
- **Database**: Supabase (PostgreSQL)
- **Language**: TypeScript

## Deployment

Deploy to Vercel, Netlify, or any Node.js hosting platform:

1. Set environment variables in your hosting platform
2. Run `npm run build`
3. Run `npm start` or use the platform's auto-deploy

## Security Notes

- The Supabase anon key is used (safe for client-side)
- Row Level Security (RLS) should be enabled on the `ai_config` table
- Consider adding authentication for production use
- Restrict write access to admin users only

## Future Enhancements

- [ ] Add authentication (Supabase Auth)
- [ ] Test interface for trying models with sample inputs
- [ ] Model cost calculator
- [ ] Prompt version history
- [ ] A/B testing capabilities
- [ ] Real-time updates across multiple admin sessions
