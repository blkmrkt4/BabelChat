# Web-Admin Deployment & Monitoring Setup Guide

This guide will help you deploy your web-admin to Vercel and set up automated health checks with SMS alerts.

## Current Status

✅ SMS alerts working (shortened messages for trial account)
✅ Authentication system implemented (login required)
✅ Monitoring dashboard created
✅ Settings page with SMS test buttons
✅ Database tables created in Supabase

## What's Left to Complete

❌ Deploy web-admin to Vercel
❌ Set up cron job for automated health checks
❌ Add alert configuration to Supabase
❌ Test end-to-end monitoring

---

## Step 1: Add Alert Configuration to Supabase (5 minutes)

Before deploying, you need to configure the alert system in your Supabase database.

### 1.1 Go to Supabase SQL Editor
- URL: https://supabase.com/dashboard/project/ckhukylfoeofvoxvwwin/sql/new

### 1.2 Run This SQL

```sql
-- Add SMS alert configuration for your monitoring system
INSERT INTO alert_config (
  alert_type,
  destination,
  enabled,
  failure_threshold,
  cooldown_minutes,
  services
)
VALUES (
  'sms',
  '+14378607068',  -- Your Canadian primary number
  true,
  3,                -- Alert after 3 consecutive failures
  60,               -- Wait 60 minutes before re-alerting
  ARRAY['openrouter']
);

-- Verify it was created
SELECT * FROM alert_config;
```

### 1.3 Expected Result
You should see 1 row returned with:
- `alert_type`: sms
- `destination`: +14378607068
- `enabled`: true
- `failure_threshold`: 3
- `cooldown_minutes`: 60

---

## Step 2: Deploy to Vercel (10 minutes)

### 2.1 Push Code to GitHub

If you haven't already committed your latest changes:

```bash
cd /Users/blkmrkt/Documents/Code/LangiOS/LangChat/web-admin
git add .
git commit -m "Add authentication and monitoring system"
git push
```

### 2.2 Sign Up for Vercel

1. Go to: https://vercel.com/signup
2. Click **"Continue with GitHub"**
3. Authorize Vercel to access your GitHub account

### 2.3 Import Your Project

1. Click **"Add New..."** → **"Project"**
2. Find your **LangChat** repository
3. Click **"Import"**

### 2.4 Configure Project Settings

**Root Directory:**
- Set to: `web-admin`
- Click **"Edit"** next to "Root Directory"
- Type: `web-admin`
- Click **"Continue"**

**Framework Preset:**
- Should auto-detect as **Next.js** ✅

### 2.5 Add Environment Variables

Click **"Environment Variables"** and add each of these:

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# OpenRouter API Key
NEXT_PUBLIC_OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_API_KEY=sk-or-v1-your-key-here

# Twilio Account
ALERT_PHONE_NUMBER=your-phone-number
ALERT_PHONE_NUMBER_BACKUP=your-backup-phone
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=your-twilio-phone
TWILIO_MESSAGING_SERVICE_SID=your-messaging-service-sid

# Health Check Secret
HEALTH_CHECK_SECRET=your-secret-passphrase-here

# Base URL (will be your Vercel URL after deployment)
NEXT_PUBLIC_BASE_URL=https://your-app-name.vercel.app
```

**IMPORTANT:**
- For `SUPABASE_SERVICE_ROLE_KEY`, go to your Supabase project Settings → API
- Copy the "service_role" key (NOT the anon key)
- For Twilio credentials, get them from your Twilio console
- For `NEXT_PUBLIC_BASE_URL`, use your Vercel deployment URL (you'll update this after first deploy)

### 2.6 Deploy

1. Click **"Deploy"**
2. Wait 2-3 minutes for build to complete
3. You'll get a URL like: `https://your-app-name.vercel.app`

### 2.7 Update Base URL

1. Go to your Vercel project settings
2. Click **"Environment Variables"**
3. Find `NEXT_PUBLIC_BASE_URL`
4. Click **"Edit"**
5. Change value to your actual Vercel URL: `https://your-app-name.vercel.app`
6. Click **"Save"**
7. Go to **"Deployments"** tab
8. Click **"..."** next to your latest deployment → **"Redeploy"** → **"Redeploy"**

---

## Step 3: Set Up Cron Job (5 minutes)

Now that your app is deployed, you need to set up automated health checks every 15 minutes.

### 3.1 Sign Up for Cron-Job.org

1. Go to: https://cron-job.org/en/signup/
2. Create a free account
3. Verify your email

### 3.2 Create New Cron Job

1. Click **"Cronjobs"** in the sidebar
2. Click **"Create cronjob"**

### 3.3 Configure Cron Job

**Title:**
```
LangChat Health Check
```

**Address:**
```
https://your-app-name.vercel.app/api/health-check
```
(Replace with your actual Vercel URL)

**Schedule:**
- **Every 15 minutes**
- Or use cron expression: `*/15 * * * *`

**Request Settings:**
- **Request method**: GET
- Click **"Advanced"**
- **Request headers**: Add this header:
  ```
  Authorization: Bearer Ihave3kidsCalumMarleySloan
  ```

**Notification Settings:**
- Enable **"Enable notifications in case of execution failures"**
- Add your email

### 3.4 Save and Enable

1. Click **"Create cronjob"**
2. Make sure it's **enabled** (toggle should be green)

---

## Step 4: Test Everything (10 minutes)

### 4.1 Test Login

1. Go to your Vercel URL: `https://your-app-name.vercel.app`
2. You should be redirected to `/login`
3. Enter your Supabase credentials
4. You should see the admin dashboard

### 4.2 Test Settings Page

1. Click the **⚙️ gear icon** in the navigation
2. Click **"Test Primary"**
3. Check your Canadian phone (+1-437-860-7068)
4. You should receive: "LangChat Test: Primary SMS monitoring is working. Alerts configured correctly."

### 4.3 Manually Trigger Health Check

1. Go to cron-job.org
2. Click your **"LangChat Health Check"** job
3. Click **"Run"** (play button icon)
4. Wait 10-15 seconds
5. Check the execution history - should show **"Success"**

### 4.4 Check Monitoring Dashboard

1. Go to: `https://your-app-name.vercel.app/monitoring`
2. You should see health check data
3. All services should show as **"UP"** (green)

### 4.5 Check Supabase Database

1. Go to Supabase Table Editor
2. Check `api_health_checks` table: https://supabase.com/dashboard/project/ckhukylfoeofvoxvwwin/editor
3. You should see recent health check records

---

## Step 5: Verify SMS Alerts Work (Optional)

To test that you actually receive SMS when something breaks:

### Option 1: Temporarily Break Your API Key

1. Go to Vercel environment variables
2. Change `OPENROUTER_API_KEY` to something invalid like: `sk-invalid-key`
3. Redeploy
4. Wait 45 minutes (3 health checks × 15 min)
5. You should receive SMS: "LangChat Alert: openrouter DOWN (3x). Check dashboard."
6. **Don't forget to restore the correct API key!**

### Option 2: Check Alert History

After the system runs for a while, check Supabase `alert_history` table to see if any alerts were sent.

---

## What Happens Now

### Every 15 Minutes:
1. Cron-job.org calls your `/api/health-check` endpoint
2. Your app tests all 3 AI models (translation, grammar, scoring)
3. Results are logged to `api_health_checks` table in Supabase
4. If 3+ consecutive failures detected, SMS is sent to +14378607068

### When You Get an SMS:
The message will look like:
```
LangChat Alert: openrouter DOWN (3x). Check dashboard.
```

This means:
- Service has failed 3+ times in a row (~45 minutes of downtime)
- You should check your dashboard at: `https://your-app-name.vercel.app/monitoring`
- You won't get another alert for 60 minutes (cooldown period)

---

## Costs

### Monthly Costs:
- **Vercel**: $0 (free tier, plenty for this use case)
- **Cron-job.org**: $0 (free tier, up to 3 jobs)
- **Twilio**: ~$1.25-1.50/month
  - Phone number rental: $1.15/month
  - SMS to Canada: ~$0.0079 per message
  - Expected usage: 1-2 alerts per month = ~$0.02-0.05

**Total: ~$1.25-1.50/month**

---

## Troubleshooting

### "Unauthorized" Error from Health Check
- Check that your `HEALTH_CHECK_SECRET` in Vercel matches the one in cron-job.org
- Make sure Authorization header is set correctly: `Bearer Ihave3kidsCalumMarleySloan`

### No Health Check Data in Supabase
- Check cron-job.org execution history for errors
- Verify Vercel deployment succeeded
- Check Vercel function logs for errors

### SMS Not Received
- Check Supabase `alert_history` table - was alert actually sent?
- Verify phone number is correct in `alert_config` table
- Check Twilio logs: https://console.twilio.com/us1/monitor/logs/sms
- Remember: Trial account = 160 character limit

### Can't Login to Web-Admin
- Make sure you created a user in Supabase Auth
- Check browser console for errors
- Verify `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are set in Vercel

---

## Upgrading Twilio (Recommended)

To remove SMS length restrictions and enable UK number:

1. Go to: https://console.twilio.com/us1/billing/manage-billing/billing-overview
2. Add credit card + $20
3. All restrictions lifted immediately:
   - ✅ Send to UK number (+447769301448)
   - ✅ Longer messages with emojis
   - ✅ No verified number requirement

Cost stays the same: ~$1.25-1.50/month

---

## Support & Monitoring

### Check System Status:
- **Dashboard**: `https://your-app-name.vercel.app/monitoring`
- **Settings**: `https://your-app-name.vercel.app/settings` (test SMS)
- **Cron Job Status**: https://cron-job.org/en/members/jobs/

### Logs:
- **Vercel Logs**: https://vercel.com/dashboard → Your Project → Logs
- **Twilio SMS Logs**: https://console.twilio.com/us1/monitor/logs/sms
- **Cron Job Logs**: https://cron-job.org/en/members/jobs/ → Your Job → History

---

## Summary Checklist

Before deployment:
- [ ] Alert configuration added to Supabase
- [ ] Code committed and pushed to GitHub
- [ ] Supabase service_role key obtained

During deployment:
- [ ] Vercel account created
- [ ] Project imported from GitHub
- [ ] Root directory set to `web-admin`
- [ ] All environment variables added
- [ ] First deployment successful
- [ ] `NEXT_PUBLIC_BASE_URL` updated with Vercel URL
- [ ] Redeployed after URL update

After deployment:
- [ ] Cron-job.org account created
- [ ] Cron job configured (every 15 minutes)
- [ ] Authorization header set
- [ ] Cron job enabled
- [ ] Login tested
- [ ] SMS test successful
- [ ] Manual health check triggered
- [ ] Monitoring dashboard shows data

You're done! 🎉

Your monitoring system is now running 24/7, checking your AI models every 15 minutes and sending SMS alerts when something goes down.
