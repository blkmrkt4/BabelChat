# Simple Monitoring Setup - SMS Alerts Only

This will monitor your OpenRouter API and send you an SMS when something is actually broken (3+ consecutive failures).

## Cost: ~$1.25/month ($15/year)

---

## Step 1: Install Dependencies

```bash
cd web-admin
npm install twilio
```

## Step 2: Sign Up for Twilio (5 minutes)

1. Go to https://www.twilio.com/try-twilio
2. Sign up (free trial gives you $15 credit)
3. Get a phone number:
   - Click "Get a Trial Number" button
   - Accept the number they give you
   - Copy it (format: +15555551234)

4. Get your credentials:
   - Go to https://console.twilio.com
   - Copy your **Account SID**
   - Copy your **Auth Token** (click eye icon to reveal)

## Step 3: Add Environment Variables

Edit `web-admin/.env.local` and add:

```bash
# Add these new lines:
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15555551234  # Your Twilio number
ALERT_PHONE_NUMBER=+1YOUR_REAL_PHONE  # Your personal phone (include country code)

# Generate a random secret (just mash keyboard):
HEALTH_CHECK_SECRET=sdkfjh23498sdfjkhsdf9234

# Your app URL (after deploying to Vercel):
NEXT_PUBLIC_BASE_URL=https://your-app.vercel.app
```

## Step 4: Run SQL in Supabase (2 minutes)

1. Go to https://supabase.com/dashboard/project/ckhukylfoeofvoxvwwin
2. Click "SQL Editor" in left sidebar
3. Click "New Query"
4. Copy and paste from `supabase/monitoring_schema.sql`
5. Click "Run"
6. You should see: "Success. No rows returned"

## Step 5: Deploy to Vercel

```bash
cd web-admin
vercel --prod
```

After deploying, copy your URL (e.g., `https://your-app.vercel.app`)

## Step 6: Set Up Cron Job (5 minutes)

1. Go to https://cron-job.org/en/
2. Sign up (free, no credit card)
3. Click "Create cronjob"
4. Fill in:
   - **Title**: LangChat Health Check
   - **URL**: `https://your-app.vercel.app/api/health-check`
   - **Schedule**:
     - Click "Every 15 minutes" preset
   - **Advanced** tab:
     - Click "Enable advanced"
     - Add Custom header:
       - Name: `Authorization`
       - Value: `Bearer YOUR_HEALTH_CHECK_SECRET` (from .env.local)
5. Click "Create cronjob"

## Step 7: Test It Works

### Test the health check:

```bash
curl -H "Authorization: Bearer YOUR_HEALTH_CHECK_SECRET" \
  https://your-app.vercel.app/api/health-check
```

You should see JSON response like:
```json
{
  "success": true,
  "tested": 3,
  "results": [...]
}
```

### Test SMS (optional):

```bash
curl -X POST https://your-app.vercel.app/api/send-sms \
  -H "Authorization: Bearer YOUR_HEALTH_CHECK_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "+1YOUR_PHONE",
    "message": "Test alert from LangChat",
    "priority": "critical"
  }'
```

You should receive an SMS within seconds.

## Step 8: View Dashboard

Go to: `https://your-app.vercel.app/monitoring`

You should see:
- ✅ Green banner if everything is up
- 🚨 Red banner if something is down
- Service cards showing status for Translation, Grammar, Scoring

## How It Works

1. **Every 15 minutes**: Cron job calls your health check endpoint
2. **Health check tests**: Translation, Grammar, and Scoring APIs
3. **If 3+ consecutive failures**: SMS sent to your phone
4. **Cooldown**: Won't spam - only 1 SMS per hour per service
5. **Dashboard**: Check anytime at `/monitoring` page

## When You'll Get SMS

You'll ONLY get SMS when:
- ✅ 3+ consecutive failures (service actually down)
- ✅ Real fatal issues (OpenRouter API down, wrong API key, etc.)
- ❌ NOT for single transient failures
- ❌ NOT for slow responses (unless they timeout)

## Cost Breakdown

- Twilio phone number: $1.15/month
- SMS (US): $0.0079 each
- Expected failures: 1-10/month
- **Total: ~$1.25/month or $15/year**

## Troubleshooting

### "No rows returned" in Supabase
✅ This is normal! It means the SQL ran successfully.

### "401 Unauthorized" when testing
❌ Your `HEALTH_CHECK_SECRET` doesn't match. Check `.env.local`

### SMS not receiving
1. Check Twilio console for errors
2. Verify phone number includes country code (+1 for US)
3. Check you have Twilio credit (free trial gives $15)

### Dashboard shows "Unknown"
- Wait 15 minutes for first health check to run
- Or trigger manually with the curl command above

## What's Next

Once running, you can:
- Check dashboard anytime to see status
- Receive SMS only when something is actually broken
- Review `api_health_checks` table in Supabase for history
- Adjust cooldown time if you want more/fewer alerts

---

That's it! Your monitoring is set up. You'll get an SMS when OpenRouter or Supabase is actually down, and you can check the dashboard anytime to see current status.
