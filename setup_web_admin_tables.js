#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const path = require('path')

// Load environment variables
require('dotenv').config()

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env file')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function executeSqlFile(filePath) {
  console.log(`\n📄 Executing ${path.basename(filePath)}...`)

  try {
    const sql = fs.readFileSync(filePath, 'utf8')

    // Split by semicolons but be careful with function definitions
    const statements = sql
      .split(/;(?=\s*(?:CREATE|INSERT|ALTER|DROP|COMMENT|--|\n|$))/i)
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'))

    for (const statement of statements) {
      if (statement.trim()) {
        const { data, error } = await supabase.rpc('exec_sql', {
          sql_query: statement + ';'
        }).catch(async () => {
          // If exec_sql doesn't exist, try direct query
          return await supabase.from('_sql').insert({ query: statement })
        })

        if (error) {
          console.error(`⚠️  Error in statement: ${error.message}`)
          // Don't exit, continue with other statements
        }
      }
    }

    console.log(`✅ Completed ${path.basename(filePath)}`)
  } catch (error) {
    console.error(`❌ Error reading file ${filePath}:`, error.message)
  }
}

async function setupDatabase() {
  console.log('🚀 Setting up web admin database tables...\n')
  console.log(`📡 Connecting to: ${supabaseUrl}`)

  const sqlFiles = [
    './supabase/create_ai_config_table.sql',
    './supabase/add_fallback_models_to_ai_config.sql',
    './supabase/create_model_evaluations_table.sql',
    './supabase/seed_ai_config.sql'
  ]

  for (const file of sqlFiles) {
    const filePath = path.join(__dirname, file)
    if (fs.existsSync(filePath)) {
      await executeSqlFile(filePath)
    } else {
      console.log(`⚠️  File not found: ${file}`)
    }
  }

  console.log('\n✨ Database setup complete!')
  console.log('\n📝 Verifying tables...')

  // Verify tables were created
  const { data: aiConfig, error: aiError } = await supabase
    .from('ai_config')
    .select('category, model_name')
    .limit(3)

  if (aiError) {
    console.error('❌ ai_config table check failed:', aiError.message)
  } else {
    console.log('✅ ai_config table exists:', aiConfig?.length || 0, 'records')
  }

  const { data: evaluations, error: evalError } = await supabase
    .from('model_evaluations')
    .select('id')
    .limit(1)

  if (evalError) {
    console.error('❌ model_evaluations table check failed:', evalError.message)
  } else {
    console.log('✅ model_evaluations table exists')
  }
}

setupDatabase().catch(console.error)
